using System;
using System.IO;
using System.Runtime.InteropServices;
using System.Threading;
using System.Threading.Tasks;
using System.Runtime.InteropServices.ComTypes; // For IStream

namespace IcDesk.Windows
{
    public class DXGICaptureEngine : IDisposable
    {
        private bool _isInitialized = false;
        private ID3D11Device _device;
        private ID3D11DeviceContext _context;
        private IDXGIOutputDuplication _duplication;
        private IMFSinkWriter _sinkWriter;
        private uint _streamIndex;
        private long _rtStart;
        
        private IStream _memoryStream;
        private IMFByteStream _mfByteStream;

        [DllImport("ole32.dll", PreserveSig = true)]
        private static extern int CreateStreamOnHGlobal(IntPtr hGlobal, bool fDeleteOnRelease, out IStream ppstm);

        [DllImport("ole32.dll", PreserveSig = true)]
        private static extern int GetHGlobalFromStream(IStream pstm, out IntPtr phglobal);

        [DllImport("kernel32.dll")]
        private static extern IntPtr GlobalLock(IntPtr hMem);

        [DllImport("kernel32.dll")]
        private static extern bool GlobalUnlock(IntPtr hMem);

        [DllImport("kernel32.dll")]
        private static extern UIntPtr GlobalSize(IntPtr hMem);

        [DllImport("mfplat.dll", ExactSpelling = true, PreserveSig = true)]
        private static extern int MFCreateMFByteStreamOnStream(IStream pStream, out IMFByteStream ppByteStream);

        // Required interface because it's not in DXGI_Interop_Scratch
        [ComImport, Guid("279AFA85-4981-11CE-A521-0020AF0BE560"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
        public interface IMFByteStream {
            void GetCapabilities(out uint pdwCapabilities);
            void GetLength(out ulong pqwLength);
            void SetLength(ulong qwLength);
            void GetCurrentPosition(out ulong pqwPosition);
            void SetCurrentPosition(ulong qwPosition);
            void IsEndOfStream(out bool pfEndOfStream);
            void Read(IntPtr pb, uint cb, out uint pcbRead);
            void BeginRead(IntPtr pb, uint cb, IntPtr pCallback, IntPtr punkState);
            void EndRead(IntPtr pResult, out uint pcbRead);
            void Write(IntPtr pb, uint cb, out uint pcbWritten);
            void BeginWrite(IntPtr pb, uint cb, IntPtr pCallback, IntPtr punkState);
            void EndWrite(IntPtr pResult, out uint pcbWritten);
            void Seek(uint mfSeekOrigin, long llSeekOffset, uint dwSeekFlags, out ulong pqwCurrentPosition);
            void Flush();
            void Close();
        }

        private long _lastReadPosition = 0;

        public void Initialize()
        {
            if (_isInitialized) return;

            NativeMethods.MFStartup(MFConstants.MF_VERSION);

            var featureLevels = new[] { D3D_FEATURE_LEVEL.LEVEL_11_0 };
            int hr = NativeMethods.D3D11CreateDevice(IntPtr.Zero, D3D_DRIVER_TYPE.HARDWARE, IntPtr.Zero,
                D3D11_CREATE_DEVICE_FLAG.BGRA_SUPPORT, featureLevels, 1, 7, out _device, out _, out _context);
            if (hr < 0) throw new Exception("D3D11CreateDevice failed");

            var dxgiDevice = (IDXGIDevice)_device;
            dxgiDevice.GetAdapter(out var dxgiAdapter);
            dxgiAdapter.EnumOutputs(0, out var dxgiOutput);
            var dxgiOutput1 = (IDXGIOutput1)dxgiOutput;
            hr = dxgiOutput1.DuplicateOutput(_device, out _duplication);
            if (hr < 0) throw new Exception("DuplicateOutput failed");

            // Create memory stream
            hr = CreateStreamOnHGlobal(IntPtr.Zero, true, out _memoryStream);
            if (hr < 0) throw new Exception("CreateStreamOnHGlobal failed");

            hr = MFCreateMFByteStreamOnStream(_memoryStream, out _mfByteStream);
            if (hr < 0) throw new Exception("MFCreateMFByteStreamOnStream failed");

            IntPtr pByteStream = Marshal.GetComInterfaceForObject(_mfByteStream, typeof(IMFByteStream));
            
            // Pass ".mp4" to use the MP4 sink. 
            // Wait, passing null or ".h264" might work. MP4 sink is usually better for raw H264 but .h264 works for annex b.
            hr = NativeMethods.MFCreateSinkWriterFromURL(".h264", pByteStream, null, out _sinkWriter);
            Marshal.Release(pByteStream);
            if (hr < 0) throw new Exception("MFCreateSinkWriterFromURL failed");

            NativeMethods.MFCreateMediaType(out var mediaTypeOut);
            Guid mtVideo = MFConstants.MFMediaType_Video;
            mediaTypeOut.SetGUID(ref MFConstants.MF_MT_MAJOR_TYPE, ref mtVideo);
            Guid formatH264 = MFConstants.MFVideoFormat_H264;
            mediaTypeOut.SetGUID(ref MFConstants.MF_MT_SUBTYPE, ref formatH264);
            mediaTypeOut.SetUINT32(ref MFConstants.MF_MT_AVG_BITRATE, 4000000); // 4 Mbps
            mediaTypeOut.SetUINT32(ref MFConstants.MF_MT_INTERLACE_MODE, 2); // Progressive
            mediaTypeOut.SetUINT64(ref MFConstants.MF_MT_FRAME_SIZE, MFConstants.PackSize(1920, 1080));
            mediaTypeOut.SetUINT64(ref MFConstants.MF_MT_FRAME_RATE, MFConstants.PackRatio(30, 1));
            mediaTypeOut.SetUINT32(ref MFConstants.MF_MT_PIXEL_ASPECT_RATIO, (uint)MFConstants.PackRatio(1, 1));
            _sinkWriter.AddStream(mediaTypeOut, out _streamIndex);

            NativeMethods.MFCreateMediaType(out var mediaTypeIn);
            mediaTypeIn.SetGUID(ref MFConstants.MF_MT_MAJOR_TYPE, ref mtVideo);
            Guid formatBgra = MFConstants.MFVideoFormat_ARGB32; // DXGI Format B8G8R8A8
            mediaTypeIn.SetGUID(ref MFConstants.MF_MT_SUBTYPE, ref formatBgra);
            mediaTypeIn.SetUINT32(ref MFConstants.MF_MT_INTERLACE_MODE, 2);
            mediaTypeIn.SetUINT64(ref MFConstants.MF_MT_FRAME_SIZE, MFConstants.PackSize(1920, 1080));
            mediaTypeIn.SetUINT64(ref MFConstants.MF_MT_FRAME_RATE, MFConstants.PackRatio(30, 1));
            mediaTypeIn.SetUINT32(ref MFConstants.MF_MT_PIXEL_ASPECT_RATIO, (uint)MFConstants.PackRatio(1, 1));
            _sinkWriter.SetInputMediaType(_streamIndex, mediaTypeIn, null);

            _sinkWriter.BeginWriting();
            _rtStart = DateTime.UtcNow.Ticks;
            _lastReadPosition = 0;
            _isInitialized = true;
        }

        [DllImport("msvcrt.dll", EntryPoint = "memcpy", CallingConvention = CallingConvention.Cdecl, SetLastError = false)]
        public static extern IntPtr memcpy(IntPtr dest, IntPtr src, UIntPtr count);

        public byte[] CaptureFrame()
        {
            if (!_isInitialized) return null;

            int hr = _duplication.AcquireNextFrame(100, out var frameInfo, out var desktopResource);
            if (hr < 0 || desktopResource == null) return new byte[0];

            using (var d3dTexture = new ComObjectWrapper<ID3D11Texture2D>((ID3D11Texture2D)desktopResource))
            {
                // Create staging texture
                D3D11_TEXTURE2D_DESC desc;
                d3dTexture.Instance.GetDesc(out desc);
                desc.Usage = 3; // STAGING
                desc.BindFlags = 0;
                desc.CPUAccessFlags = 0x20000; // READ
                desc.MiscFlags = 0;

                _device.CreateTexture2D(ref desc, IntPtr.Zero, out var stagingTex);
                _context.CopyResource(Marshal.GetComInterfaceForObject(stagingTex, typeof(ID3D11Texture2D)), 
                                      Marshal.GetComInterfaceForObject(d3dTexture.Instance, typeof(ID3D11Texture2D)));

                _context.Map(Marshal.GetComInterfaceForObject(stagingTex, typeof(ID3D11Texture2D)), 0, 1, 0, out var mapped);
                
                // Write to MF Sample
                uint cbMaxLength = desc.Height * mapped.RowPitch;
                NativeMethods.MFCreateMemoryBuffer(cbMaxLength, out var mfBuffer);
                mfBuffer.Lock(out var mfPtr, out _, out _);
                
                // memcpy mapped.pData to mfPtr
                // We use msvcrt.dll memcpy or simple Copy
                try {
                    memcpy(mfPtr, mapped.pData, (UIntPtr)cbMaxLength);
                } catch {
                    // Fallback if memcpy not available (on Windows it usually is)
                }

                mfBuffer.Unlock();
                mfBuffer.SetCurrentLength(cbMaxLength);

                NativeMethods.MFCreateSample(out var mfSample);
                mfSample.AddBuffer(mfBuffer);
                long timestamp = (DateTime.UtcNow.Ticks - _rtStart) * 10; // 100-nanosecond units (1 tick = 100ns)
                mfSample.SetSampleTime(timestamp);
                mfSample.SetSampleDuration(333333); // ~30 fps

                _sinkWriter.WriteSample(_streamIndex, mfSample);
                _context.Unmap(Marshal.GetComInterfaceForObject(stagingTex, typeof(ID3D11Texture2D)), 0);
                Marshal.ReleaseComObject(stagingTex);
            }

            _duplication.ReleaseFrame();
            
            // Wait a little bit for asynchronous encoder to output
            // But ideally we'd just read what's available
            _mfByteStream.Flush();

            // Now read from _memoryStream
            // We can read via HGlobal
            if (GetHGlobalFromStream(_memoryStream, out IntPtr hGlobal) == 0)
            {
                IntPtr pMem = GlobalLock(hGlobal);
                long currentSize = (long)GlobalSize(hGlobal);
                
                if (currentSize > _lastReadPosition)
                {
                    long newBytes = currentSize - _lastReadPosition;
                    byte[] naluData = new byte[newBytes];
                    Marshal.Copy(new IntPtr(pMem.ToInt64() + _lastReadPosition), naluData, 0, (int)newBytes);
                    _lastReadPosition = currentSize;
                    GlobalUnlock(hGlobal);
                    return naluData;
                }
                GlobalUnlock(hGlobal);
            }

            return new byte[0];
        }

        public void Dispose()
        {
            if (_sinkWriter != null)
            {
                _sinkWriter.Finalize();
                Marshal.ReleaseComObject(_sinkWriter);
                _sinkWriter = null;
            }
            if (_mfByteStream != null)
            {
                Marshal.ReleaseComObject(_mfByteStream);
                _mfByteStream = null;
            }
            if (_memoryStream != null)
            {
                Marshal.ReleaseComObject(_memoryStream);
                _memoryStream = null;
            }
            if (_duplication != null)
            {
                Marshal.ReleaseComObject(_duplication);
                _duplication = null;
            }
            if (_context != null)
            {
                Marshal.ReleaseComObject(_context);
                _context = null;
            }
            if (_device != null)
            {
                Marshal.ReleaseComObject(_device);
                _device = null;
            }
            NativeMethods.MFShutdown();
            _isInitialized = false;
        }

        private class ComObjectWrapper<T> : IDisposable where T : class
        {
            public T Instance { get; private set; }
            public ComObjectWrapper(T instance) { Instance = instance; }
            public void Dispose() { if (Instance != null) { Marshal.ReleaseComObject(Instance); Instance = null; } }
        }
    }
}

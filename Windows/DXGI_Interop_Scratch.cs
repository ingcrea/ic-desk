using System;
using System.Runtime.InteropServices;

namespace IcDesk.Windows
{
    // -------------------------------------------------------------------------
    // GUIDs for COM Interfaces
    // -------------------------------------------------------------------------
    public static class COMGuids
    {
        public const string IID_ID3D11Device = "db6f6ddb-ac77-4e88-8253-819df9bbf140";
        public const string IID_ID3D11DeviceContext = "c0bfa96c-e089-44fb-8eaf-26f8796190da";
        public const string IID_ID3D11Texture2D = "6f15aaf2-d208-4e89-9ab4-489535d34f9c";
        public const string IID_IDXGIObject = "aec222be-7cf3-4fac-b35b-c2e6cb1fae13";
        public const string IID_IDXGIDevice = "54ec77fa-1377-44e6-8c32-88fd5f44c84c";
        public const string IID_IDXGIAdapter = "2411e7e1-12ac-4ccf-bd14-9798e8534dc0";
        public const string IID_IDXGIFactory = "7b7166ec-21c7-44ae-b21a-c9ae321ae369";
        public const string IID_IDXGIFactory1 = "770aae78-f26f-4dba-a829-253c83d1b387";
        public const string IID_IDXGIOutput = "ae02eedb-c735-4690-8d52-5a8dc20213aa";
        public const string IID_IDXGIOutput1 = "00cddea8-939b-4b83-a340-a685226666cc";
        public const string IID_IDXGIOutputDuplication = "191cfac3-a341-470d-b26e-a864f428319c";
        public const string IID_IDXGIResource = "035f3ab4-482e-4e50-b41f-8a7f8bd8960b";
        public const string IID_IMFSinkWriter = "3137f1cd-fe5e-4805-a5d8-fb477448cb3d";
        public const string IID_IMFMediaBuffer = "045FA593-8799-42b8-BC8D-8968C6453507";
        public const string IID_IMF2DBuffer = "7DC9D5F9-9ED9-44EC-9BBF-0600BB589FBB";
        public const string IID_IMFSample = "c40a00f2-b93a-4d80-ae8c-5a1c634f58e4";
        public const string IID_IMFMediaType = "44ae0fa8-ea31-4109-8d2e-4cae4997c555";
        public const string IID_IMFAttributes = "2cd2d921-c447-44a7-a13c-4adabfc247e3";
    }

    // -------------------------------------------------------------------------
    // Enums and Structs
    // -------------------------------------------------------------------------
    public enum D3D_DRIVER_TYPE
    {
        UNKNOWN = 0,
        HARDWARE = 1,
        REFERENCE = 2,
        NULL = 3,
        SOFTWARE = 4,
        WARP = 5
    }

    [Flags]
    public enum D3D11_CREATE_DEVICE_FLAG
    {
        NONE = 0,
        SINGLETHREADED = 0x1,
        DEBUG = 0x2,
        SWITCH_TO_REF = 0x4,
        PREVENT_INTERNAL_THREADING_OPTIMIZATIONS = 0x8,
        BGRA_SUPPORT = 0x20
    }

    public enum D3D_FEATURE_LEVEL
    {
        LEVEL_9_1 = 0x9100,
        LEVEL_9_2 = 0x9200,
        LEVEL_9_3 = 0x9300,
        LEVEL_10_0 = 0xa000,
        LEVEL_10_1 = 0xa100,
        LEVEL_11_0 = 0xb000,
        LEVEL_11_1 = 0xb100
    }

    public enum DXGI_FORMAT
    {
        UNKNOWN = 0,
        B8G8R8A8_UNORM = 87
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct DXGI_OUTDUPL_FRAME_INFO
    {
        public long LastPresentTime;
        public long LastMouseUpdateTime;
        public uint AccumulatedFrames;
        public uint RectsCoalesced;
        public uint ProtectedContentMaskedOut;
        public DXGI_OUTDUPL_POINTER_POSITION PointerPosition;
        public uint TotalMetadataBufferSize;
        public uint PointerShapeBufferSize;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct DXGI_OUTDUPL_POINTER_POSITION
    {
        public POINT Position;
        public int Visible;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct POINT
    {
        public int X;
        public int Y;
    }
    
    [StructLayout(LayoutKind.Sequential)]
    public struct RECT
    {
        public int Left;
        public int Top;
        public int Right;
        public int Bottom;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct D3D11_TEXTURE2D_DESC
    {
        public uint Width;
        public uint Height;
        public uint MipLevels;
        public uint ArraySize;
        public DXGI_FORMAT Format;
        public DXGI_SAMPLE_DESC SampleDesc;
        public uint Usage;
        public uint BindFlags;
        public uint CPUAccessFlags;
        public uint MiscFlags;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct DXGI_SAMPLE_DESC
    {
        public uint Count;
        public uint Quality;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct D3D11_MAPPED_SUBRESOURCE
    {
        public IntPtr pData;
        public uint RowPitch;
        public uint DepthPitch;
    }

    // -------------------------------------------------------------------------
    // Interfaces (D3D11 & DXGI)
    // -------------------------------------------------------------------------
    [ComImport]
    [Guid(COMGuids.IID_ID3D11Device)]
    [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    public interface ID3D11Device
    {
        [PreserveSig]
        int CreateBuffer(IntPtr pDesc, IntPtr pInitialData, out IntPtr ppBuffer);
        
        [PreserveSig]
        int CreateTexture1D(IntPtr pDesc, IntPtr pInitialData, out IntPtr ppTexture1D);
        
        [PreserveSig]
        int CreateTexture2D(ref D3D11_TEXTURE2D_DESC pDesc, IntPtr pInitialData, out ID3D11Texture2D ppTexture2D);
        
        void PlaceHolder_03();
        void PlaceHolder_04();
        void PlaceHolder_05();
        void PlaceHolder_06();
        void PlaceHolder_07();
        void PlaceHolder_08();
        void PlaceHolder_09();
        void PlaceHolder_10();
        void PlaceHolder_11();
        void PlaceHolder_12();
        void PlaceHolder_13();
        void PlaceHolder_14();
        void PlaceHolder_15();
        void PlaceHolder_16();
        void PlaceHolder_17();
        void PlaceHolder_18();
        void PlaceHolder_19();
        void PlaceHolder_20();
        void PlaceHolder_21();
        void PlaceHolder_22();
        void PlaceHolder_23();
        void PlaceHolder_24();
        void PlaceHolder_25();
        void PlaceHolder_26();
        void PlaceHolder_27();
        void PlaceHolder_28();
        void PlaceHolder_29();
        void PlaceHolder_30();
        void PlaceHolder_31();
        void PlaceHolder_32();
        void PlaceHolder_33();
        void PlaceHolder_34();
        void PlaceHolder_35();
        void PlaceHolder_36();
        void PlaceHolder_37();
        
        [PreserveSig]
        int GetImmediateContext(out ID3D11DeviceContext ppImmediateContext);
    }

    [ComImport]
    [Guid(COMGuids.IID_ID3D11Texture2D)]
    [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    public interface ID3D11Texture2D
    {
        void GetDevice();
        void GetPrivateData();
        void SetPrivateData();
        void SetPrivateDataInterface();
        void GetType();
        void SetEvictionPriority();
        void GetEvictionPriority();
        void GetDesc(out D3D11_TEXTURE2D_DESC pDesc);
    }

    [ComImport]
    [Guid(COMGuids.IID_ID3D11DeviceContext)]
    [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    public interface ID3D11DeviceContext
    {
        void VSSetConstantBuffers();
        void PSSetShaderResources();
        void PSSetShader();
        void SAMPLERSetSamplers();
        void VSSetShader();
        void DrawIndexed();
        void Draw();
        
        [PreserveSig]
        int Map(IntPtr pResource, uint Subresource, uint MapType, uint MapFlags, out D3D11_MAPPED_SUBRESOURCE pMappedResource);
        
        [PreserveSig]
        void Unmap(IntPtr pResource, uint Subresource);
        
        void PSSetConstantBuffers();
        void IASetInputLayout();
        void IASetVertexBuffers();
        void IASetIndexBuffer();
        void DrawIndexedInstanced();
        void DrawInstanced();
        void GSSetConstantBuffers();
        void GSSetShader();
        void IASetPrimitiveTopology();
        void VSSetShaderResources();
        void VSSetSamplers();
        void Begin();
        void End();
        void GetData();
        void SetPredication();
        void GSSetShaderResources();
        void GSSetSamplers();
        void OMSetRenderTargets();
        void OMSetRenderTargetsAndUnorderedAccessViews();
        void OMSetBlendState();
        void OMSetDepthStencilState();
        void SOSetTargets();
        void DrawAuto();
        void DrawIndexedInstancedIndirect();
        void DrawInstancedIndirect();
        void Dispatch();
        void DispatchIndirect();
        void RSSetState();
        void RSSetViewports();
        void RSSetScissorRects();
        
        [PreserveSig]
        void CopySubresourceRegion(IntPtr pDstResource, uint DstSubresource, uint DstX, uint DstY, uint DstZ, IntPtr pSrcResource, uint SrcSubresource, IntPtr pSrcBox);
        
        [PreserveSig]
        void CopyResource(IntPtr pDstResource, IntPtr pSrcResource);
        
        [PreserveSig]
        void UpdateSubresource(IntPtr pDstResource, uint DstSubresource, IntPtr pDstBox, IntPtr pSrcData, uint SrcRowPitch, uint SrcDepthPitch);
        
        void CopyStructureCount();
        void ClearRenderTargetView();
        void ClearUnorderedAccessViewUint();
        void ClearUnorderedAccessViewFloat();
        void ClearDepthStencilView();
        void GenerateMips();
        void SetResourceMinLOD();
        void GetResourceMinLOD();
        void ResolveSubresource();
        void ExecuteCommandList();
        void HSSetShaderResources();
        void HSSetShader();
        void HSSetSamplers();
        void HSSetConstantBuffers();
        void DSSetShaderResources();
        void DSSetShader();
        void DSSetSamplers();
        void DSSetConstantBuffers();
        void CSSetShaderResources();
        void CSSetUnorderedAccessViews();
        void CSSetShader();
        void CSSetSamplers();
        void CSSetConstantBuffers();
        void VSGetConstantBuffers();
        void PSGetShaderResources();
        void PSGetShader();
        void VSGetShader();
        void PSGetSamplers();
        void IAGetInputLayout();
        void IAGetVertexBuffers();
        void IAGetIndexBuffer();
        void GSGetConstantBuffers();
        void GSGetShader();
        void IAGetPrimitiveTopology();
        void VSGetShaderResources();
        void VSGetSamplers();
        void GetPredication();
        void GSGetShaderResources();
        void GSGetSamplers();
        void OMGetRenderTargets();
        void OMGetRenderTargetsAndUnorderedAccessViews();
        void OMGetBlendState();
        void OMGetDepthStencilState();
        void SOGetTargets();
        void RSGetState();
        void RSGetViewports();
        void RSGetScissorRects();
        void HSGetShaderResources();
        void HSGetShader();
        void HSGetSamplers();
        void HSGetConstantBuffers();
        void DSGetShaderResources();
        void DSGetShader();
        void DSGetSamplers();
        void DSGetConstantBuffers();
        void CSGetShaderResources();
        void CSGetUnorderedAccessViews();
        void CSGetShader();
        void CSGetSamplers();
        void CSGetConstantBuffers();
        void ClearState();
        void Flush();
        void GetType();
        void GetContextFlags();
        void FinishCommandList();
    }

    [ComImport]
    [Guid(COMGuids.IID_IDXGIObject)]
    [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    public interface IDXGIObject
    {
        [PreserveSig]
        int SetPrivateData(ref Guid Name, uint DataSize, IntPtr pData);
        [PreserveSig]
        int SetPrivateDataInterface(ref Guid Name, [MarshalAs(UnmanagedType.IUnknown)] object pUnknown);
        [PreserveSig]
        int GetPrivateData(ref Guid Name, ref uint pDataSize, IntPtr pData);
        [PreserveSig]
        int GetParent(ref Guid riid, out IntPtr ppParent);
    }

    [ComImport]
    [Guid(COMGuids.IID_IDXGIAdapter)]
    [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    public interface IDXGIAdapter : IDXGIObject
    {
        new int SetPrivateData(ref Guid Name, uint DataSize, IntPtr pData);
        new int SetPrivateDataInterface(ref Guid Name, [MarshalAs(UnmanagedType.IUnknown)] object pUnknown);
        new int GetPrivateData(ref Guid Name, ref uint pDataSize, IntPtr pData);
        new int GetParent(ref Guid riid, out IntPtr ppParent);
        
        [PreserveSig]
        int EnumOutputs(uint Output, out IDXGIOutput ppOutput);
        [PreserveSig]
        int GetDesc(IntPtr pDesc);
        [PreserveSig]
        int CheckInterfaceSupport(ref Guid InterfaceName, out long pUMDVersion);
    }

    [ComImport]
    [Guid(COMGuids.IID_IDXGIDevice)]
    [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    public interface IDXGIDevice : IDXGIObject
    {
        new int SetPrivateData(ref Guid Name, uint DataSize, IntPtr pData);
        new int SetPrivateDataInterface(ref Guid Name, [MarshalAs(UnmanagedType.IUnknown)] object pUnknown);
        new int GetPrivateData(ref Guid Name, ref uint pDataSize, IntPtr pData);
        new int GetParent(ref Guid riid, out IntPtr ppParent);

        [PreserveSig]
        int GetAdapter(out IDXGIAdapter pAdapter);
        [PreserveSig]
        int CreateSurface();
        [PreserveSig]
        int QueryResourceResidency();
        [PreserveSig]
        int SetGPUThreadPriority(int Priority);
        [PreserveSig]
        int GetGPUThreadPriority(out int pPriority);
    }

    [ComImport]
    [Guid(COMGuids.IID_IDXGIOutput)]
    [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    public interface IDXGIOutput : IDXGIObject
    {
        new int SetPrivateData(ref Guid Name, uint DataSize, IntPtr pData);
        new int SetPrivateDataInterface(ref Guid Name, [MarshalAs(UnmanagedType.IUnknown)] object pUnknown);
        new int GetPrivateData(ref Guid Name, ref uint pDataSize, IntPtr pData);
        new int GetParent(ref Guid riid, out IntPtr ppParent);

        [PreserveSig]
        int GetDesc(IntPtr pDesc);
        [PreserveSig]
        int GetDisplayModeList(DXGI_FORMAT EnumFormat, uint Flags, ref uint pNumModes, IntPtr pDesc);
        [PreserveSig]
        int FindClosestMatchingMode(IntPtr pModeToMatch, IntPtr pClosestMatch, [MarshalAs(UnmanagedType.IUnknown)] object pConcernedDevice);
        [PreserveSig]
        int WaitForVBlank();
        [PreserveSig]
        int TakeOwnership([MarshalAs(UnmanagedType.IUnknown)] object pDevice, int Exclusive);
        [PreserveSig]
        void ReleaseOwnership();
        [PreserveSig]
        int GetGammaControlCapabilities(IntPtr pGammaCaps);
        [PreserveSig]
        int SetGammaControl(IntPtr pArray);
        [PreserveSig]
        int GetGammaControl(IntPtr pArray);
        [PreserveSig]
        int SetDisplaySurface(IntPtr pScanoutSurface);
        [PreserveSig]
        int GetDisplaySurfaceData(IntPtr pDestination);
        [PreserveSig]
        int GetFrameStatistics(IntPtr pStats);
    }

    [ComImport]
    [Guid(COMGuids.IID_IDXGIOutput1)]
    [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    public interface IDXGIOutput1 : IDXGIOutput
    {
        new int SetPrivateData(ref Guid Name, uint DataSize, IntPtr pData);
        new int SetPrivateDataInterface(ref Guid Name, [MarshalAs(UnmanagedType.IUnknown)] object pUnknown);
        new int GetPrivateData(ref Guid Name, ref uint pDataSize, IntPtr pData);
        new int GetParent(ref Guid riid, out IntPtr ppParent);

        new int GetDesc(IntPtr pDesc);
        new int GetDisplayModeList(DXGI_FORMAT EnumFormat, uint Flags, ref uint pNumModes, IntPtr pDesc);
        new int FindClosestMatchingMode(IntPtr pModeToMatch, IntPtr pClosestMatch, [MarshalAs(UnmanagedType.IUnknown)] object pConcernedDevice);
        new int WaitForVBlank();
        new int TakeOwnership([MarshalAs(UnmanagedType.IUnknown)] object pDevice, int Exclusive);
        new void ReleaseOwnership();
        new int GetGammaControlCapabilities(IntPtr pGammaCaps);
        new int SetGammaControl(IntPtr pArray);
        new int GetGammaControl(IntPtr pArray);
        new int SetDisplaySurface(IntPtr pScanoutSurface);
        new int GetDisplaySurfaceData(IntPtr pDestination);
        new int GetFrameStatistics(IntPtr pStats);

        [PreserveSig]
        int GetDisplayModeList1(DXGI_FORMAT EnumFormat, uint Flags, ref uint pNumModes, IntPtr pDesc);
        [PreserveSig]
        int FindClosestMatchingMode1(IntPtr pModeToMatch, IntPtr pClosestMatch, [MarshalAs(UnmanagedType.IUnknown)] object pConcernedDevice);
        [PreserveSig]
        int GetDisplaySurfaceData1(IntPtr pDestination);
        [PreserveSig]
        int DuplicateOutput([MarshalAs(UnmanagedType.IUnknown)] object pDevice, out IDXGIOutputDuplication ppOutputDuplication);
    }

    [ComImport]
    [Guid(COMGuids.IID_IDXGIOutputDuplication)]
    [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    public interface IDXGIOutputDuplication : IDXGIObject
    {
        new int SetPrivateData(ref Guid Name, uint DataSize, IntPtr pData);
        new int SetPrivateDataInterface(ref Guid Name, [MarshalAs(UnmanagedType.IUnknown)] object pUnknown);
        new int GetPrivateData(ref Guid Name, ref uint pDataSize, IntPtr pData);
        new int GetParent(ref Guid riid, out IntPtr ppParent);

        [PreserveSig]
        void GetDesc(IntPtr pDesc);
        [PreserveSig]
        int AcquireNextFrame(uint TimeoutInMilliseconds, out DXGI_OUTDUPL_FRAME_INFO pFrameInfo, out IDXGIResource ppDesktopResource);
        [PreserveSig]
        int GetFrameDirtyRects(uint DirtyRectsBufferSize, IntPtr pDirtyRectsBuffer, out uint pDirtyRectsBufferSizeRequired);
        [PreserveSig]
        int GetFrameMoveRects(uint MoveRectsBufferSize, IntPtr pMoveRectBuffer, out uint pMoveRectsBufferSizeRequired);
        [PreserveSig]
        int GetFramePointerShape(uint PointerShapeBufferSize, IntPtr pPointerShapeBuffer, out uint pPointerShapeBufferSizeRequired, out DXGI_OUTDUPL_POINTER_SHAPE_INFO pPointerShapeInfo);
        [PreserveSig]
        int MapDesktopSurface(out DXGI_MAPPED_RECT pLockedRect);
        [PreserveSig]
        int UnMapDesktopSurface();
        [PreserveSig]
        int ReleaseFrame();
    }
    
    [StructLayout(LayoutKind.Sequential)]
    public struct DXGI_OUTDUPL_POINTER_SHAPE_INFO
    {
        public uint Type;
        public uint Width;
        public uint Height;
        public uint Pitch;
        public POINT HotSpot;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct DXGI_MAPPED_RECT
    {
        public int Pitch;
        public IntPtr pBits;
    }

    [ComImport]
    [Guid(COMGuids.IID_IDXGIResource)]
    [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    public interface IDXGIResource : IDXGIObject
    {
        new int SetPrivateData(ref Guid Name, uint DataSize, IntPtr pData);
        new int SetPrivateDataInterface(ref Guid Name, [MarshalAs(UnmanagedType.IUnknown)] object pUnknown);
        new int GetPrivateData(ref Guid Name, ref uint pDataSize, IntPtr pData);
        new int GetParent(ref Guid riid, out IntPtr ppParent);

        [PreserveSig]
        int GetSharedHandle(out IntPtr pSharedHandle);
        [PreserveSig]
        int GetUsage(out uint pUsage);
        [PreserveSig]
        int SetEvictionPriority(uint EvictionPriority);
        [PreserveSig]
        int GetEvictionPriority(out uint pEvictionPriority);
    }

    // -------------------------------------------------------------------------
    // Media Foundation Interfaces
    // -------------------------------------------------------------------------
    [ComImport]
    [Guid(COMGuids.IID_IMFAttributes)]
    [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    public interface IMFAttributes
    {
        [PreserveSig] int GetItem(ref Guid guidKey, IntPtr pValue);
        [PreserveSig] int GetItemType(ref Guid guidKey, out int pType);
        [PreserveSig] int CompareItem(ref Guid guidKey, IntPtr Value, out int pbResult);
        [PreserveSig] int Compare(IMFAttributes pTheirs, int MatchType, out int pbResult);
        [PreserveSig] int GetUINT32(ref Guid guidKey, out uint punValue);
        [PreserveSig] int GetUINT64(ref Guid guidKey, out ulong punValue);
        [PreserveSig] int GetDouble(ref Guid guidKey, out double pfValue);
        [PreserveSig] int GetGUID(ref Guid guidKey, out Guid pguidValue);
        [PreserveSig] int GetStringLength(ref Guid guidKey, out uint pcchLength);
        [PreserveSig] int GetString(ref Guid guidKey, [Out, MarshalAs(UnmanagedType.LPWStr)] System.Text.StringBuilder pwszValue, uint cchBufSize, out uint pcchLength);
        [PreserveSig] int GetAllocatedString(ref Guid guidKey, out IntPtr ppwszValue, out uint pcchLength);
        [PreserveSig] int GetBlobSize(ref Guid guidKey, out uint pcbBlobSize);
        [PreserveSig] int GetBlob(ref Guid guidKey, [Out, MarshalAs(UnmanagedType.LPArray)] byte[] pBuf, uint cbBufSize, out uint pcbBlobSize);
        [PreserveSig] int GetAllocatedBlob(ref Guid guidKey, out IntPtr ppBuf, out uint pcbSize);
        [PreserveSig] int GetUnknown(ref Guid guidKey, ref Guid riid, [MarshalAs(UnmanagedType.IUnknown)] out object ppv);
        [PreserveSig] int SetItem(ref Guid guidKey, IntPtr Value);
        [PreserveSig] int DeleteItem(ref Guid guidKey);
        [PreserveSig] int DeleteAllItems();
        [PreserveSig] int SetUINT32(ref Guid guidKey, uint unValue);
        [PreserveSig] int SetUINT64(ref Guid guidKey, ulong unValue);
        [PreserveSig] int SetDouble(ref Guid guidKey, double fValue);
        [PreserveSig] int SetGUID(ref Guid guidKey, ref Guid guidValue);
        [PreserveSig] int SetString(ref Guid guidKey, [In, MarshalAs(UnmanagedType.LPWStr)] string wszValue);
        [PreserveSig] int SetBlob(ref Guid guidKey, [In, MarshalAs(UnmanagedType.LPArray, SizeParamIndex = 2)] byte[] pBuf, uint cbBufSize);
        [PreserveSig] int SetUnknown(ref Guid guidKey, [In, MarshalAs(UnmanagedType.IUnknown)] object pUnknown);
        [PreserveSig] int LockStore();
        [PreserveSig] int UnlockStore();
        [PreserveSig] int GetCount(out uint pcItems);
        [PreserveSig] int GetItemByIndex(uint unIndex, out Guid pguidKey, IntPtr pValue);
        [PreserveSig] int CopyAllItems(IMFAttributes pDest);
    }

    [ComImport]
    [Guid(COMGuids.IID_IMFMediaType)]
    [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    public interface IMFMediaType : IMFAttributes
    {
        new int GetItem(ref Guid guidKey, IntPtr pValue);
        new int GetItemType(ref Guid guidKey, out int pType);
        new int CompareItem(ref Guid guidKey, IntPtr Value, out int pbResult);
        new int Compare(IMFAttributes pTheirs, int MatchType, out int pbResult);
        new int GetUINT32(ref Guid guidKey, out uint punValue);
        new int GetUINT64(ref Guid guidKey, out ulong punValue);
        new int GetDouble(ref Guid guidKey, out double pfValue);
        new int GetGUID(ref Guid guidKey, out Guid pguidValue);
        new int GetStringLength(ref Guid guidKey, out uint pcchLength);
        new int GetString(ref Guid guidKey, [Out, MarshalAs(UnmanagedType.LPWStr)] System.Text.StringBuilder pwszValue, uint cchBufSize, out uint pcchLength);
        new int GetAllocatedString(ref Guid guidKey, out IntPtr ppwszValue, out uint pcchLength);
        new int GetBlobSize(ref Guid guidKey, out uint pcbBlobSize);
        new int GetBlob(ref Guid guidKey, [Out, MarshalAs(UnmanagedType.LPArray)] byte[] pBuf, uint cbBufSize, out uint pcbBlobSize);
        new int GetAllocatedBlob(ref Guid guidKey, out IntPtr ppBuf, out uint pcbSize);
        new int GetUnknown(ref Guid guidKey, ref Guid riid, [MarshalAs(UnmanagedType.IUnknown)] out object ppv);
        new int SetItem(ref Guid guidKey, IntPtr Value);
        new int DeleteItem(ref Guid guidKey);
        new int DeleteAllItems();
        new int SetUINT32(ref Guid guidKey, uint unValue);
        new int SetUINT64(ref Guid guidKey, ulong unValue);
        new int SetDouble(ref Guid guidKey, double fValue);
        new int SetGUID(ref Guid guidKey, ref Guid guidValue);
        new int SetString(ref Guid guidKey, [In, MarshalAs(UnmanagedType.LPWStr)] string wszValue);
        new int SetBlob(ref Guid guidKey, [In, MarshalAs(UnmanagedType.LPArray, SizeParamIndex = 2)] byte[] pBuf, uint cbBufSize);
        new int SetUnknown(ref Guid guidKey, [In, MarshalAs(UnmanagedType.IUnknown)] object pUnknown);
        new int LockStore();
        new int UnlockStore();
        new int GetCount(out uint pcItems);
        new int GetItemByIndex(uint unIndex, out Guid pguidKey, IntPtr pValue);
        new int CopyAllItems(IMFAttributes pDest);

        [PreserveSig] int GetMajorType(out Guid pguidMajorType);
        [PreserveSig] int IsCompressedFormat(out int pfCompressed);
        [PreserveSig] int IsEqual(IMFMediaType pIMediaType, ref uint pdwFlags);
        [PreserveSig] int GetRepresentation(Guid guidRepresentation, out IntPtr ppvRepresentation);
        [PreserveSig] int FreeRepresentation(Guid guidRepresentation, IntPtr pvRepresentation);
    }
    
    [ComImport]
    [Guid(COMGuids.IID_IMFMediaBuffer)]
    [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    public interface IMFMediaBuffer
    {
        [PreserveSig] int Lock(out IntPtr ppbBuffer, out uint pcbMaxLength, out uint pcbCurrentLength);
        [PreserveSig] int Unlock();
        [PreserveSig] int GetCurrentLength(out uint pcbCurrentLength);
        [PreserveSig] int SetCurrentLength(uint cbCurrentLength);
        [PreserveSig] int GetMaxLength(out uint pcbMaxLength);
    }
    
    [ComImport]
    [Guid(COMGuids.IID_IMF2DBuffer)]
    [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    public interface IMF2DBuffer
    {
        [PreserveSig] int Lock2D(out IntPtr ppbScanline0, out int plPitch);
        [PreserveSig] int Unlock2D();
        [PreserveSig] int GetScanline0AndPitch(out IntPtr ppbScanline0, out int plPitch);
        [PreserveSig] int IsContiguousFormat(out int pfIsContiguous);
        [PreserveSig] int GetContiguousLength(out uint pcbLength);
        [PreserveSig] int ContiguousCopyTo(IntPtr pbDestBuffer, uint cbDestBuffer);
        [PreserveSig] int ContiguousCopyFrom(IntPtr pbSrcBuffer, uint cbSrcBuffer);
    }
    
    [ComImport]
    [Guid(COMGuids.IID_IMFSample)]
    [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    public interface IMFSample : IMFAttributes
    {
        new int GetItem(ref Guid guidKey, IntPtr pValue);
        new int GetItemType(ref Guid guidKey, out int pType);
        new int CompareItem(ref Guid guidKey, IntPtr Value, out int pbResult);
        new int Compare(IMFAttributes pTheirs, int MatchType, out int pbResult);
        new int GetUINT32(ref Guid guidKey, out uint punValue);
        new int GetUINT64(ref Guid guidKey, out ulong punValue);
        new int GetDouble(ref Guid guidKey, out double pfValue);
        new int GetGUID(ref Guid guidKey, out Guid pguidValue);
        new int GetStringLength(ref Guid guidKey, out uint pcchLength);
        new int GetString(ref Guid guidKey, [Out, MarshalAs(UnmanagedType.LPWStr)] System.Text.StringBuilder pwszValue, uint cchBufSize, out uint pcchLength);
        new int GetAllocatedString(ref Guid guidKey, out IntPtr ppwszValue, out uint pcchLength);
        new int GetBlobSize(ref Guid guidKey, out uint pcbBlobSize);
        new int GetBlob(ref Guid guidKey, [Out, MarshalAs(UnmanagedType.LPArray)] byte[] pBuf, uint cbBufSize, out uint pcbBlobSize);
        new int GetAllocatedBlob(ref Guid guidKey, out IntPtr ppBuf, out uint pcbSize);
        new int GetUnknown(ref Guid guidKey, ref Guid riid, [MarshalAs(UnmanagedType.IUnknown)] out object ppv);
        new int SetItem(ref Guid guidKey, IntPtr Value);
        new int DeleteItem(ref Guid guidKey);
        new int DeleteAllItems();
        new int SetUINT32(ref Guid guidKey, uint unValue);
        new int SetUINT64(ref Guid guidKey, ulong unValue);
        new int SetDouble(ref Guid guidKey, double fValue);
        new int SetGUID(ref Guid guidKey, ref Guid guidValue);
        new int SetString(ref Guid guidKey, [In, MarshalAs(UnmanagedType.LPWStr)] string wszValue);
        new int SetBlob(ref Guid guidKey, [In, MarshalAs(UnmanagedType.LPArray, SizeParamIndex = 2)] byte[] pBuf, uint cbBufSize);
        new int SetUnknown(ref Guid guidKey, [In, MarshalAs(UnmanagedType.IUnknown)] object pUnknown);
        new int LockStore();
        new int UnlockStore();
        new int GetCount(out uint pcItems);
        new int GetItemByIndex(uint unIndex, out Guid pguidKey, IntPtr pValue);
        new int CopyAllItems(IMFAttributes pDest);

        [PreserveSig] int GetSampleFlags(out uint pdwSampleFlags);
        [PreserveSig] int SetSampleFlags(uint dwSampleFlags);
        [PreserveSig] int GetSampleTime(out long phnsSampleTime);
        [PreserveSig] int SetSampleTime(long hnsSampleTime);
        [PreserveSig] int GetSampleDuration(out long phnsSampleDuration);
        [PreserveSig] int SetSampleDuration(long hnsSampleDuration);
        [PreserveSig] int GetBufferCount(out uint pdwBufferCount);
        [PreserveSig] int GetBufferByIndex(uint dwIndex, out IMFMediaBuffer ppBuffer);
        [PreserveSig] int ConvertToContiguousBuffer(out IMFMediaBuffer ppBuffer);
        [PreserveSig] int AddBuffer(IMFMediaBuffer pBuffer);
        [PreserveSig] int RemoveBufferByIndex(uint dwIndex);
        [PreserveSig] int RemoveAllBuffers();
        [PreserveSig] int GetTotalLength(out uint pcbTotalLength);
        [PreserveSig] int CopyToBuffer(IMFMediaBuffer pBuffer);
    }
    
    [ComImport]
    [Guid(COMGuids.IID_IMFSinkWriter)]
    [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    public interface IMFSinkWriter
    {
        [PreserveSig] int AddStream(IMFMediaType pTargetMediaType, out uint pdwStreamIndex);
        [PreserveSig] int SetInputMediaType(uint dwStreamIndex, IMFMediaType pInputMediaType, IMFAttributes pEncodingParameters);
        [PreserveSig] int BeginWriting();
        [PreserveSig] int WriteSample(uint dwStreamIndex, IMFSample pSample);
        [PreserveSig] int SendStreamTick(uint dwStreamIndex, long llTimestamp);
        [PreserveSig] int PlaceMarker(uint dwStreamIndex, IntPtr pvContext);
        [PreserveSig] int NotifyEndOfSegment(uint dwStreamIndex);
        [PreserveSig] int Flush(uint dwStreamIndex);
        [PreserveSig] int Finalize();
        [PreserveSig] int GetServiceForStream(uint dwStreamIndex, ref Guid guidService, ref Guid riid, [MarshalAs(UnmanagedType.IUnknown)] out object ppvObject);
        [PreserveSig] int GetStatistics(uint dwStreamIndex, IntPtr pStats);
    }

    // -------------------------------------------------------------------------
    // DllImports
    // -------------------------------------------------------------------------
    public static class NativeMethods
    {
        [DllImport("d3d11.dll", CallingConvention = CallingConvention.StdCall, PreserveSig = true)]
        public static extern int D3D11CreateDevice(
            IntPtr pAdapter,
            D3D_DRIVER_TYPE DriverType,
            IntPtr Software,
            D3D11_CREATE_DEVICE_FLAG Flags,
            [In, MarshalAs(UnmanagedType.LPArray)] D3D_FEATURE_LEVEL[] pFeatureLevels,
            uint FeatureLevels,
            uint SDKVersion,
            out ID3D11Device ppDevice,
            out D3D_FEATURE_LEVEL pFeatureLevel,
            out ID3D11DeviceContext ppImmediateContext);

        [DllImport("mfplat.dll", CallingConvention = CallingConvention.StdCall, PreserveSig = true)]
        public static extern int MFStartup(uint Version, uint dwFlags = 0);

        [DllImport("mfplat.dll", CallingConvention = CallingConvention.StdCall, PreserveSig = true)]
        public static extern int MFShutdown();
        
        [DllImport("mfplat.dll", CallingConvention = CallingConvention.StdCall, PreserveSig = true)]
        public static extern int MFCreateMediaType(out IMFMediaType ppMFType);

        [DllImport("mfplat.dll", CallingConvention = CallingConvention.StdCall, PreserveSig = true)]
        public static extern int MFCreateSample(out IMFSample ppIMFSample);

        [DllImport("mfplat.dll", CallingConvention = CallingConvention.StdCall, PreserveSig = true)]
        public static extern int MFCreateMemoryBuffer(uint cbMaxLength, out IMFMediaBuffer ppBuffer);

        [DllImport("mfreadwrite.dll", CallingConvention = CallingConvention.StdCall, PreserveSig = true, CharSet = CharSet.Unicode)]
        public static extern int MFCreateSinkWriterFromURL(
            string pwszOutputURL,
            IntPtr pByteStream,
            IMFAttributes pAttributes,
            out IMFSinkWriter ppSinkWriter);
            
        [DllImport("mfplat.dll", CallingConvention = CallingConvention.StdCall, PreserveSig = true)]
        public static extern int MFCreateDXGISurfaceBuffer(
            ref Guid riid, 
            [MarshalAs(UnmanagedType.IUnknown)] object punkSurface, 
            uint uSubresourceIndex, 
            bool fBottomUpWhenLinear, 
            out IMFMediaBuffer ppBuffer);
    }

    // -------------------------------------------------------------------------
    // Constants & Helpers
    // -------------------------------------------------------------------------
    public static class MFConstants
    {
        public const uint MF_VERSION = 0x00020070; // MF_SDK_VERSION | MF_API_VERSION
        
        public static Guid MF_MT_MAJOR_TYPE = new Guid("48eba18e-f8c9-4687-bf11-0a74c9f96a8f");
        public static Guid MF_MT_SUBTYPE = new Guid("f7e34c9a-42e8-4714-b74b-cb29d72c35e5");
        public static Guid MF_MT_AVG_BITRATE = new Guid("20332624-fb0d-4d9e-bd0d-cbf6786c102e");
        public static Guid MF_MT_INTERLACE_MODE = new Guid("e2724bb8-e676-4806-b4b2-a8d6efb44ccd");
        public static Guid MF_MT_FRAME_SIZE = new Guid("1652c33d-d6b2-4012-b834-72030849a37d");
        public static Guid MF_MT_FRAME_RATE = new Guid("c459a2e8-3d2c-4e44-b132-fee5156c7bb0");
        public static Guid MF_MT_PIXEL_ASPECT_RATIO = new Guid("c6376a1e-8d0a-4027-be45-6d9a0ad39bb6");

        public static Guid MFMediaType_Video = new Guid("73646976-0000-0010-8000-00aa00389b71");
        public static Guid MFVideoFormat_H264 = new Guid("34363248-0000-0010-8000-00aa00389b71");
        public static Guid MFVideoFormat_NV12 = new Guid("3231564e-0000-0010-8000-00aa00389b71");
        public static Guid MFVideoFormat_RGB32 = new Guid("00000016-0000-0010-8000-00aa00389b71"); 
        public static Guid MFVideoFormat_ARGB32 = new Guid("00000015-0000-0010-8000-00aa00389b71");
        
        public static Guid MF_SINK_WRITER_DISABLE_THROTTLING = new Guid("08b845d8-2b74-4afe-9d53-be16d2d5ae4f");
        public static Guid MF_READWRITE_ENABLE_HARDWARE_TRANSFORMS = new Guid("a634a91c-822b-41b9-a494-4de4643612b0");
        
        public static ulong PackSize(uint width, uint height)
        {
            return ((ulong)width << 32) | (height);
        }

        public static ulong PackRatio(uint numerator, uint denominator)
        {
            return ((ulong)numerator << 32) | (denominator);
        }
    }
}

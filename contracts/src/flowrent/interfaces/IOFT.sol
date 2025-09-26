// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

interface IOFT {
    // Send tokens to another chain
    function sendFrom(
        address _from,
        uint16 _dstChainId,
        bytes calldata _toAddress,
        uint _amount,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes calldata _adapterParams
    ) external payable;
    
    // Estimate fee for sending tokens to another chain
    function estimateSendFee(
        uint16 _dstChainId,
        bytes calldata _toAddress,
        uint _amount,
        bool _useZro,
        bytes calldata _adapterParams
    ) external view returns (uint nativeFee, uint zroFee);
    
    // Get the CirculatingSupply on this chain
    function circulatingSupply() external view returns (uint);
    
    // Get the address of the token
    function token() external view returns (address);
    
    // Set the minimum amount of tokens required for a send
    function setMinDstGas(uint16 _dstChainId, uint _packetType, uint _minGas) external;
    
    // Set a precrime address for detecting malicious transactions
    function setPrecrime(address _precrime) external;
    
    // Get the minimum amount of tokens required for a send
    function minDstGasLookup(uint16 _dstChainId, uint _packetType) external view returns (uint);
    
    // Get the trusted remote address for a specific chain
    function trustedRemoteLookup(uint16 _remoteChainId) external view returns (bytes memory);
    
    // Set a trusted remote address for a specific chain
    function setTrustedRemote(uint16 _remoteChainId, bytes calldata _path) external;
    
    // Set a trusted remote address for a specific chain with extra parameters
    function setTrustedRemoteAddress(uint16 _remoteChainId, bytes calldata _remoteAddress) external;
    
    // Get the layer zero endpoint address
    function lzEndpoint() external view returns (address);
}

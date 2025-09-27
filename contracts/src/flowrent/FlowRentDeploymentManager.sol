// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./FlowRentEscrow.sol";
import "./FlowRentOracle.sol";

/**
 * @title FlowRentDeploymentManager
 * @notice Ultra-slim deployment manager for FlowRent escrow and oracle contracts
 * @dev This contract is minimized to reduce contract size
 */
contract FlowRentDeploymentManager is Ownable {
    
    constructor(address _owner) Ownable(_owner) {}
    
    /**
     * @notice Deploy escrow contract
     * @param pyusdToken PYUSD token address
     * @param verificationContract Verification contract address
     * @param sablierLockupContract Sablier lockup contract address
     * @return escrow The deployed escrow contract
     */
    function deployEscrow(
        address pyusdToken,
        address verificationContract,
        address sablierLockupContract
    ) external onlyOwner returns (FlowRentEscrow) {
        return new FlowRentEscrow(
            pyusdToken,
            verificationContract,
            sablierLockupContract,
            owner()
        );
    }
    
    /**
     * @notice Deploy oracle contract
     * @param escrowContract The escrow contract address
     * @return oracle The deployed oracle contract
     */
    function deployOracle(address escrowContract) external onlyOwner returns (FlowRentOracle) {
        return new FlowRentOracle(escrowContract, owner());
    }
    
    /**
     * @notice Deploy both escrow and oracle contracts together
     * @param pyusdToken PYUSD token address
     * @param verificationContract Verification contract address
     * @param sablierLockupContract Sablier lockup contract address
     * @return escrowContract The deployed escrow contract address
     * @return oracleContract The deployed oracle contract address
     */
    function deployEscrowAndOracle(
        address pyusdToken,
        address verificationContract,
        address sablierLockupContract
    ) external onlyOwner returns (
        address escrowContract,
        address oracleContract
    ) {
        // Deploy FlowRentEscrow
        FlowRentEscrow escrow = new FlowRentEscrow(
            pyusdToken,
            verificationContract,
            sablierLockupContract,
            owner()
        );
        escrowContract = address(escrow);

        // Deploy FlowRentOracle
        FlowRentOracle oracle = new FlowRentOracle(
            escrowContract,
            owner()
        );
        oracleContract = address(oracle);
        
        return (escrowContract, oracleContract);
    }
}

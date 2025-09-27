// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./FlowRentEscrow.sol";
import "./FlowRentOracle.sol";

/**
 * @title FlowRentRegistry
 * @notice Storage contract for FlowRent deployments to further reduce the size of FlowRentFactoryCore
 * @dev Only contains storage and view functions to separate concerns
 */
contract FlowRentRegistry is Ownable {
    // Contract addresses
    struct FlowRentDeployment {
        address escrowContract;
        address oracleContract;
        address pyusdToken;
        address verificationContract;
        uint256 deploymentBlock;
        string version;
    }

    // Deployment tracking
    mapping(string => FlowRentDeployment) public deployments;  // network => deployment
    mapping(address => bool) public isFlowRentContract;        // contract => isValid
    
    string[] public deployedNetworks;
    uint256 public totalDeployments;
    
    // Events
    event DeploymentRegistered(
        string indexed network,
        address escrowContract,
        address oracleContract
    );
    event ContractValidityChanged(address contractAddress, bool isValid);

    constructor(address _owner) Ownable(_owner) {}
    
    /**
     * @notice Register a new deployment in the registry
     * @param network Network identifier 
     * @param escrowContract Address of the escrow contract
     * @param oracleContract Address of the oracle contract
     * @param pyusdToken Address of the PYUSD token
     * @param verificationContract Address of the verification contract
     * @param version Version string for this deployment
     */
    function registerDeployment(
        string memory network,
        address escrowContract,
        address oracleContract,
        address pyusdToken,
        address verificationContract,
        string memory version
    ) external onlyOwner {
        require(bytes(network).length > 0, "Network name required");
        require(escrowContract != address(0), "Invalid escrow address");
        require(oracleContract != address(0), "Invalid oracle address");
        require(deployments[network].escrowContract == address(0), "Network already deployed");
        
        // Store deployment
        deployments[network] = FlowRentDeployment({
            escrowContract: escrowContract,
            oracleContract: oracleContract,
            pyusdToken: pyusdToken,
            verificationContract: verificationContract,
            deploymentBlock: block.number,
            version: version
        });

        // Mark contracts as valid
        setContractValidity(escrowContract, true);
        setContractValidity(oracleContract, true);

        // Update tracking
        deployedNetworks.push(network);
        totalDeployments++;

        emit DeploymentRegistered(network, escrowContract, oracleContract);
    }

    /**
     * @notice Get deployment details for a network
     * @param network Network to query
     * @return deployment Complete deployment information
     */
    function getDeployment(string memory network) external view returns (FlowRentDeployment memory deployment) {
        return deployments[network];
    }

    /**
     * @notice Get all deployed networks
     * @return networks Array of network names
     */
    function getDeployedNetworks() external view returns (string[] memory networks) {
        return deployedNetworks;
    }

    /**
     * @notice Check if an address is a valid FlowRent contract
     * @param contractAddress Address to check
     * @return isValid Whether the address is a valid FlowRent contract
     */
    function isValidFlowRentContract(address contractAddress) external view returns (bool isValid) {
        return isFlowRentContract[contractAddress];
    }
    
    /**
     * @notice Set the validity of a contract
     * @param contractAddress Contract address to update
     * @param isValid New validity status
     */
    function setContractValidity(address contractAddress, bool isValid) public onlyOwner {
        isFlowRentContract[contractAddress] = isValid;
        emit ContractValidityChanged(contractAddress, isValid);
    }
}

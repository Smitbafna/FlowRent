# FlowRent Scripts One-Line Reference

`deploy-oapp-cross-chain.sh`: Deploys verification system across Celo and Arbitrum, sets up LayerZero peers.

`DeployProofOfHumanOApp.s.sol`: Deploys verification sender on Celo.

`DeployProofOfHumanReceiver.s.sol`: Deploys verification receiver on Arbitrum.

`Base.s.sol`: Base utilities for Solidity deployment scripts.

`verify-contracts.sh`: Verifies all contracts on block explorers.

`make deploy`: Full deployment process.

`make deploy-contracts`: Contracts-only deployment.

`make set-scope`: Configures Self Protocol verification scope.

`make set-peers`: Sets up cross-chain contract connections.

`make fund-source`: Adds funds for cross-chain messaging.

`make withdraw-source`: Retrieves funds from source contract.

`make update-app-env`: Updates frontend configuration.

**Deployment Order**: 1) Configure .env → 2) Run deploy-oapp-cross-chain.sh → 3) Verify with verify-contracts.sh → 4) Fund with make fund-source

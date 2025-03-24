# IoT Perimeter Manager UI

A single-file Vue.js application for managing IoT device fleets using the ZTNAPerimeterRegistry smart contract.

## Features

- Connect with MetaMask
- View registry information
- Create new fleet instances
- Manage fleet users (add/remove)
- View shared fleets

## Prerequisites

- MetaMask browser extension installed
- Access to an Ethereum network with the ZTNAPerimeterRegistry contract deployed
- The ZTNAPerimeterRegistry contract should be deployed at `0x5FbDB2315678afecb367f032d93F642f64180aa3`

## Usage

1. Start the Anvil local Ethereum network using the provided script:
   ```bash
   ./scripts/deploy_anvil.sh
   ```

2. Open the `fleet-manager.html` file in your browser:
   - You can use a local web server: `python -m http.server` and navigate to `http://localhost:8000/ui/fleet-manager.html`
   - Or simply open the file directly in your browser

3. Connect your MetaMask wallet to the application:
   - Make sure MetaMask is connected to `localhost:8545` (Anvil)
   - Click the "Connect Wallet" button

4. Interact with the ZTNAPerimeterRegistry contract:
   - Create new fleets
   - View fleet details
   - Add/remove users to your fleets
   - View fleets shared with you

## Development

The application is built using:
- Vue.js 3 (Composition API)
- Ethers.js for Ethereum interaction
- Tailwind CSS for styling

All code is contained in a single HTML file for simplicity.

## Contract Integration

The UI interacts with the following ZTNAPerimeterRegistry contract functions:

- `Version()` - Get the registry version
- `CreateFleet()` - Create a new fleet
- `GetOwnFleetCount()` - Get the number of fleets owned by the user
- `GetOwnFleet(uint256 fleetIndex)` - Get details of a specific fleet
- `GetFleet(address fleet)` - Get details of any fleet
- `GetFleetUserCount(address fleet)` - Get the number of users in a fleet
- `GetFleetUser(address fleet, uint256 userIndex)` - Get a specific user in a fleet
- `AddFleetUser(address fleet, address user)` - Add a user to a fleet
- `RemoveFleetUser(address fleet, address user)` - Remove a user from a fleet
- `GetSharingUserCount()` - Get the number of users sharing fleets with you
- `GetSharingUser(uint256 index)` - Get a specific user sharing fleets with you
- `GetSharedFleetCount(address sender)` - Get the number of fleets shared by a specific user
- `GetSharedFleet(address sender, uint256 fleetIndex)` - Get details of a shared fleet 
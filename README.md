# BaseLoop Name Service (BLNS) - `.blup` Names
---
<img width="876" height="876" alt="1000108270" src="https://github.com/user-attachments/assets/ecc8f546-28b4-4aae-a42c-0a0af987b948" />

---
**BaseLoop Name Service (BLNS)** is a minimal, permissioned name registry on the **Base** network.  
Wallets that hold enough **BaseLoop (BLUP)** tokens can register short human-readable names under the `.blup` top-level label.

This contract intentionally **does not transfer or burn BLUP** — it only checks balances. This design works with BLUP tokens that restrict transfers but expose `balanceOf()` for holder checks.

---

## Features
- Register `.blup` names if you hold a minimum BLUP balance.
- Names have an expiry and can be renewed by the owner.
- Owners can set a small on-chain text record for each name (e.g., an address, bio, or pointer to off-chain metadata).
- Owner of the registry can update parameters (min BLUP, registration duration).
- Simple transfer of names between wallets.
- Minimal, gas-efficient, and easy to read (no OpenZeppelin).

---

## Quick Usage
1. Ensure your wallet holds at least the required BLUP (default param shown on contract).
2. Call `register("yourname")` from your wallet.
3. Use `setRecord("yourname", "ipfs://...")` to attach metadata.
4. Renew before expiration using `renew("yourname")`.

---

## Deployment
- Solidity version: `0.8.30`
- Recommended: deploy via Remix on Base network using the contract `BaseLoopNameService.sol`.
- Required constructor args:
  - `blupTokenAddress` (address of BLUP token)
  - `minBlup` (minimum BLUP balance required to register, in wei)
  - `registrationDuration` (seconds)
  - `tld` (string, e.g., ".blup")

---

## Future utilities & possible extensions
- Require BLUP staking to lock names (more robust ownership model).
- Name-to-NFT wrapping: mint an NFT representing name ownership for marketplace trading.
- DNS-like resolver for on-chain ENS-style lookups (wallet integration).
- Premium domain auctions paid with BLUP (if token transfer rules allow).
- Integration into other BaseLoop dApps (LaunchPad, Bounties, etc).

---

## License
MIT © 2026 BaseLoop Team

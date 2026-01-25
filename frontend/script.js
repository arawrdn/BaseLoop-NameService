const CONTRACT_ADDRESS = "0x9fC41d0c3c2f2A6145a5C38BbF9D4E9137A7cD10";

const ABI = [
  "function register(string calldata name) external",
  "function renew(string calldata name) external",
  "function setRecord(string calldata name, string calldata record) external",
  "function isAvailable(string calldata name) external view returns (bool)",
  "function getRecord(string calldata name) external view returns (string memory)",
  "function ownerOf(string calldata name) external view returns (address)",
  "function expiresAt(string calldata name) external view returns (uint256)"
];

let provider, signer, contract;

async function connectWallet() {
  if (!window.ethereum) {
    alert("Please install MetaMask or a Base-compatible wallet.");
    return;
  }
  provider = new ethers.providers.Web3Provider(window.ethereum);
  await provider.send("eth_requestAccounts", []);
  signer = provider.getSigner();
  contract = new ethers.Contract(CONTRACT_ADDRESS, ABI, signer);
  const address = await signer.getAddress();
  document.getElementById("status").innerText = `✅ Connected: ${address}`;
  document.getElementById("connectButton").classList.add("hidden");
  document.getElementById("register-section").classList.remove("hidden");
  document.getElementById("manage-section").classList.remove("hidden");
}

async function checkAvailability() {
  const name = document.getElementById("nameInput").value.trim();
  if (!name) return alert("Enter a valid name.");
  try {
    const available = await contract.isAvailable(name);
    const status = document.getElementById("status");
    if (available) status.innerText = `🟢 '${name}.blup' is available!`;
    else status.innerText = `🔴 '${name}.blup' is already registered.`;
  } catch (err) {
    console.error(err);
    alert("Error checking availability.");
  }
}

async function registerName() {
  const name = document.getElementById("nameInput").value.trim();
  if (!name) return alert("Enter a name first.");
  try {
    const available = await contract.isAvailable(name);
    if (!available) return alert("Name not available.");
    const tx = await contract.register(name);
    document.getElementById("status").innerText = "⏳ Waiting for c

// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/**
 * @title BaseLoop Name Service (BLNS)
 * @notice Minimal name registry that allows wallets holding a minimum BLUP balance
 *         to register `.blup` names. This contract only checks BLUP balances and
 *         does NOT transfer or consume BLUP tokens (works with transfer-restricted tokens).
 *
 * Key behaviors:
 *  - register(name): owner must hold >= minBlup
 *  - names expire after `registrationDuration` seconds
 *  - owner can renew, transfer, set text record, and change params
 */

interface IBaseLoopToken {
    function balanceOf(address account) external view returns (uint256);
}

contract BaseLoopNameService {
    // --- Registry parameters ---
    address public owner;
    address public immutable blupTokenAddress; // BLUP token address (balance query only)
    uint256 public minBlup; // required BLUP balance to register (wei, i.e., 200 * 1e18)
    uint256 public registrationDuration; // seconds that a registration lasts
    string public tld; // e.g., ".blup"

    // --- Name data ---
    struct NameRecord {
        address owner;
        uint256 expiresAt; // unix timestamp
        string record; // arbitrary on-chain text (small)
    }

    // name (lowercase string) => NameRecord
    mapping(string => NameRecord) private _names;

    // quick index of owner's names count (not exhaustive list)
    mapping(address => uint256) public namesCount;

    // Events
    event Registered(address indexed registrant, string name, uint256 expiresAt);
    event Renewed(address indexed registrant, string name, uint256 newExpiresAt);
    event RecordUpdated(address indexed registrant, string name, string record);
    event NameTransferred(address indexed from, address indexed to, string name);
    event ParamsUpdated(address indexed owner, uint256 minBlup, uint256 registrationDuration);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "owner only");
        _;
    }

    modifier onlyNameOwner(string memory name) {
        require(_isNameOwner(name, msg.sender), "not name owner");
        _;
    }

    constructor(
        address _blupTokenAddress,
        uint256 _minBlup,
        uint256 _registrationDuration,
        string memory _tld
    ) {
        require(_blupTokenAddress != address(0), "zero blup address");
        require(_registrationDuration > 0, "duration zero");

        owner = msg.sender;
        blupTokenAddress = _blupTokenAddress;
        minBlup = _minBlup;
        registrationDuration = _registrationDuration;
        tld = _tld;
    }

    // -------------------------
    // Registration logic
    // -------------------------

    /**
     * @notice Register a name if caller holds >= minBlup tokens and name is available.
     * @param name ASCII string; contract does not enforce full normalization — avoid uppercase.
     */
    function register(string calldata name) external {
        require(bytes(name).length != 0, "empty name");
        require(_isAvailable(name), "name not available");

        // require holder to have minimum BLUP balance (balanceOf only)
        uint256 balance = IBaseLoopToken(blupTokenAddress).balanceOf(msg.sender);
        require(balance >= minBlup, "insufficient BLUP balance");

        uint256 expires = block.timestamp + registrationDuration;
        _names[name] = NameRecord({owner: msg.sender, expiresAt: expires, record: ""});
        namesCount[msg.sender] += 1;

        emit Registered(msg.sender, name, expires);
    }

    /**
     * @notice Renew a name you own (or that has expired and you become new owner via register).
     * @param name the name to renew
     */
    function renew(string calldata name) external onlyNameOwner(name) {
        NameRecord storage nr = _names[name];
        // extend expiry by registrationDuration (stacked)
        if (nr.expiresAt < block.timestamp) {
            nr.expiresAt = block.timestamp + registrationDuration;
        } else {
            nr.expiresAt = nr.expiresAt + registrationDuration;
        }
        emit Renewed(msg.sender, name, nr.expiresAt);
    }

    // -------------------------
    // Records & Transfer
    // -------------------------

    /**
     * @notice Set a small text record for the name (e.g., off-chain pointer). Only name owner.
     */
    function setRecord(string calldata name, string calldata record) external onlyNameOwner(name) {
        _names[name].record = record;
        emit RecordUpdated(msg.sender, name, record);
    }

    /**
     * @notice Transfer name to another address. Only current name owner may call.
     */
    function transferName(string calldata name, address to) external onlyNameOwner(name) {
        require(to != address(0), "zero address");
        address prev = _names[name].owner;
        _names[name].owner = to;
        // adjust counts
        namesCount[prev] -= 1;
        namesCount[to] += 1;
        emit NameTransferred(prev, to, name);
    }

    // -------------------------
    // Views
    // -------------------------

    function isAvailable(string calldata name) external view returns (bool) {
        return _isAvailable(name);
    }

    function ownerOf(string calldata name) external view returns (address) {
        NameRecord memory nr = _names[name];
        if (nr.expiresAt < block.timestamp) return address(0);
        return nr.owner;
    }

    function expiresAt(string calldata name) external view returns (uint256) {
        return _names[name].expiresAt;
    }

    function getRecord(string calldata name) external view returns (string memory) {
        return _names[name].record;
    }

    // -------------------------
    // Admin / Owner functions
    // -------------------------

    function updateParams(uint256 _minBlup, uint256 _registrationDuration) external onlyOwner {
        require(_registrationDuration > 0, "duration zero");
        minBlup = _minBlup;
        registrationDuration = _registrationDuration;
        emit ParamsUpdated(msg.sender, _minBlup, _registrationDuration);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "zero address");
        address prev = owner;
        owner = newOwner;
        emit OwnershipTransferred(prev, newOwner);
    }

    // withdraw any ETH mistakenly sent to contract
    function withdrawETH(address payable to) external onlyOwner {
        require(to != address(0), "zero address");
        uint256 bal = address(this).balance;
        if (bal > 0) {
            to.transfer(bal);
        }
    }

    // -------------------------
    // Internal helpers
    // -------------------------

    function _isAvailable(string calldata name) internal view returns (bool) {
        NameRecord memory nr = _names[name];
        // available if never set or expired
        return (nr.owner == address(0) || nr.expiresAt < block.timestamp);
    }

    function _isNameOwner(string memory name, address who) internal view returns (bool) {
        NameRecord memory nr = _names[name];
        if (nr.expiresAt < block.timestamp) return false;
        return (nr.owner == who);
    }

    // fallback to accept ETH (but not used)
    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

abstract contract ReleasableERC20 is ERC20, Ownable, Pausable, ERC20Burnable {
    using SafeMath for uint256;

    uint256 private constant TOTAL_SUPPLY = 2_000_000_000 * (10 ** 18); // 2 billion tokens
    uint256 private COMMUNITY_SUPPLY = TOTAL_SUPPLY.mul(85).div(100); // 85%
    uint256 private STRATEGIC_RESERVE_SUPPLY = TOTAL_SUPPLY.mul(5).div(100); // 5%
    uint256 private CORE_CONTRIBUTOR_SUPPLY = TOTAL_SUPPLY.mul(5).div(100); // 5%
    uint256 private DEVELOPMENT_TEAM_SUPPLY = TOTAL_SUPPLY.mul(3).div(100); // 3%
    uint256 private ADVISOR_SUPPLY = TOTAL_SUPPLY.mul(2).div(100); // 2%

    uint256 private START_TIME = block.timestamp;
    uint256 private constant VESTING_MONTHS = 36;
    uint256 private constant SECONDS_PER_MONTH = 30 days;

    address private _communityWallet;
    address private _strategicReserveWallet;
    address private _coreContributorsWallet;
    address private _developmentTeamWallet;
    address private _advisorsWallet;

    mapping(address => uint256) internal _releasedTokens;

    mapping(address => uint256) internal _allocations;
    mapping(address => uint256[VESTING_MONTHS]) private _releaseSchedules;

    event TokensReleased(address indexed beneficiary, uint256 amount);

    constructor(
        address communityWallet_,
        address strategicReserveWallet_,
        address coreContributorWallet_,
        address developmentTeamWallet_,
        address advisorWallet_,
        string memory name_,
        string memory symbol_
    ) ERC20(name_, symbol_) Ownable(msg.sender) {
        require(communityWallet_ != address(0), "Community wallet cannot be zero address");
        require(coreContributorWallet_ != address(0), "Core Contributor wallet cannot be zero address");
        require(developmentTeamWallet_ != address(0), "Development Team wallet cannot be zero address");
        require(strategicReserveWallet_ != address(0), "Strategic reserve wallet cannot be zero address");
        require(advisorWallet_ != address(0), "Advisor wallet cannot be zero address");

        _communityWallet = communityWallet_;
        _coreContributorsWallet = coreContributorWallet_;
        _developmentTeamWallet = developmentTeamWallet_;
        _strategicReserveWallet = strategicReserveWallet_;
        _advisorsWallet = advisorWallet_;

        _allocations[_communityWallet] = COMMUNITY_SUPPLY;
        _allocations[_coreContributorsWallet] = CORE_CONTRIBUTOR_SUPPLY;
        _allocations[_developmentTeamWallet] = DEVELOPMENT_TEAM_SUPPLY;
        _allocations[_strategicReserveWallet] = STRATEGIC_RESERVE_SUPPLY;
        _allocations[_advisorsWallet] = ADVISOR_SUPPLY;

        _releaseSchedules[_communityWallet] = [10000, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        _releaseSchedules[_strategicReserveWallet] = [10000, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        _releaseSchedules[_coreContributorsWallet] = [278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 270];
        _releaseSchedules[_developmentTeamWallet] = [278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 270];
        _releaseSchedules[_advisorsWallet] = [278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 270];

        _mint(address(this), TOTAL_SUPPLY);
    }

    function _releaseTokens(address beneficiary, uint256 time) internal {
        require(
            _allocations[beneficiary] > 0,
            "Invalid beneficiary"
        );

        uint256 unreleased = this.getReleasableAmount(beneficiary, time);

        if (unreleased > _allocations[beneficiary]) {
            unreleased = _allocations[beneficiary];
        }

        require(unreleased > 0, "No tokens are due");

        _releasedTokens[beneficiary] = _releasedTokens[beneficiary].add(unreleased);

        _transfer(address(this), beneficiary, unreleased);

        emit TokensReleased(beneficiary, unreleased);
    }

    function getReleasableAmount(address beneficiary, uint256 timestamp) public view returns (uint256) {
        uint256 totalAllocation = _allocations[beneficiary];
        uint256[VESTING_MONTHS] memory releaseSchedule = _releaseSchedules[beneficiary];

        uint256 elapsedMonths = Math.min((timestamp.sub(START_TIME)).div(SECONDS_PER_MONTH), VESTING_MONTHS - 1);
        uint256 releasableAmount = 0;

        for (uint256 i = 0; i <= elapsedMonths; i++) {
            releasableAmount = releasableAmount.add(totalAllocation.mul(releaseSchedule[i]).div(10000));
        }

        if (releasableAmount > _releasedTokens[beneficiary]) {
            return releasableAmount.sub(_releasedTokens[beneficiary]);
        }
        return 0;
    }

    receive() external payable {}

    // Withdraw function to withdraw Bnb from the contract
    function withdraw(uint256 amount) onlyOwner external {
        require(amount > 0 && amount <= address(this).balance, "Invalid withdraw amount");

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Withdraw failed");
    }

    function transfer(address to, uint256 value) public whenNotPaused override returns (bool) {
        return super.transfer(to, value);
    }

    function transferFrom(address from, address to, uint256 value) public whenNotPaused override returns (bool) {
        return super.transferFrom(from, to, value);
    }

    function burn(uint256 value) public whenNotPaused override {
        super.burn(value);
    }

    function burnFrom(address account, uint256 value) public whenNotPaused override {
        super.burnFrom(account, value);
    }

    // Function to pause the contract (only owner can pause)
    function pause() external onlyOwner {
        _pause();
    }

    // Function to unpause the contract (only owner can unpause)
    function unpause() external onlyOwner {
        _unpause();
    }

    // Check contract balance
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function getStartTime() external view returns (uint256) {
        return START_TIME;
    }

    function getReleasedTokens(address beneficiary) external view returns (uint256) {
        return _releasedTokens[beneficiary];
    }

    function getAllocatedTokens(address beneficiary) external view returns (uint256) {
        return _allocations[beneficiary];
    }
}

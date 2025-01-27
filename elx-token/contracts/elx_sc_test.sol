// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./releasable_erc20.sol";

contract ELXTokenTest is ReleasableERC20 {
    constructor(
        address communityWallet_,
        address strategicReserveWallet_,
        address coreContributorWallet_,
        address developmentTeamWallet_,
        address advisorWallet_,
        string memory name_,
        string memory symbol_
    ) ReleasableERC20(communityWallet_, strategicReserveWallet_, coreContributorWallet_, developmentTeamWallet_, advisorWallet_, name_, symbol_) {}

    function releaseTokens(address beneficiary, uint256 time) public whenNotPaused onlyOwner {
        _releaseTokens(beneficiary, time);
    }

    function updateReleasedTokens(address beneficiary, uint256 value) external onlyOwner returns (bool) {
        _releasedTokens[beneficiary] = value;
        return true;
    }

    function updateAllocatedTokens(address beneficiary, uint256 value) external onlyOwner returns (bool) {
        _allocations[beneficiary] = value;
        return true;
    }
}

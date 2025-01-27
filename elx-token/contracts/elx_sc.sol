// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./releasable_erc20.sol";

contract ELXToken is ReleasableERC20 {
    constructor(
        address communityWallet_,
        address strategicReserveWallet_,
        address coreContributorWallet_,
        address developmentTeamWallet_,
        address advisorWallet_,
        string memory name_,
        string memory symbol_
    ) ReleasableERC20(communityWallet_, strategicReserveWallet_, coreContributorWallet_, developmentTeamWallet_, advisorWallet_, name_, symbol_) {}

    function releaseTokens(address beneficiary) public whenNotPaused onlyOwner {
        _releaseTokens(beneficiary, block.timestamp);
    }
}
const { expect } = require("chai");
const { ethers } = require("hardhat");
const { BigNumber } = require("@ethersproject/bignumber");

const walletMapping = new Map();

function getWalletName(address) {
  return walletMapping.get(address);
}

describe("ELXTokenTest", function () {
  let token, owner, communityWallet, strategicReserveWallet, coreContributorWallet, developmentTeamWallet, advisorWallet;

  before(async function () {
    [owner, communityWallet, strategicReserveWallet, coreContributorWallet, developmentTeamWallet, advisorWallet] =
      await ethers.getSigners();

    const ELXTokenTest = await ethers.getContractFactory('ELXTokenTest');

    walletMapping.set(owner.address, "owner");
    walletMapping.set(communityWallet.address, "communityWallet");
    walletMapping.set(strategicReserveWallet.address, "strategicReserveWallet");
    walletMapping.set(coreContributorWallet.address, "coreContributorWallet");
    walletMapping.set(developmentTeamWallet.address, "developmentTeamWallet");
    walletMapping.set(advisorWallet.address, "advisorWallet");
    console.log("Wallet info", [...walletMapping.entries()]);

    token = await ELXTokenTest.deploy(
      communityWallet.address,
      strategicReserveWallet.address,
      coreContributorWallet.address,
      developmentTeamWallet.address,
      advisorWallet.address,
      "ELX Token",
      "ELX"
    );
  });

  it("should release tokens correctly from month 1 to month 36", async function () {
    const SECONDS_PER_MONTH = BigNumber.from(30 * 24 * 60 * 60); // Use BigNumber for compatibility

    for (let month = 0; month <= 36; month++) {
      const startTime = BigNumber.from(await token.getStartTime());
      const time = startTime.add(SECONDS_PER_MONTH.mul(month));

      for (const wallet of [
        communityWallet,
        strategicReserveWallet,
        coreContributorWallet,
        developmentTeamWallet,
        advisorWallet,
      ]) {
        const allocated = BigNumber.from(await token.getAllocatedTokens(wallet.address));
        const releasedBefore = BigNumber.from(await token.getReleasedTokens(wallet.address));
        const releasable = BigNumber.from(await token.getReleasableAmount(wallet.address, time.toBigInt()));

        if (releasable.gt(0)) {
          await token.releaseTokens(wallet.address, time.toBigInt());



          const releasedAfter = BigNumber.from(await token.getReleasedTokens(wallet.address));
          console.log(`Month ${month}, address ${getWalletName(wallet.address)}, releasable: ${releasable.toBigInt()}, releasedBefore: ${releasedBefore.toBigInt()}, releasedAfter: ${releasedAfter.toBigInt()}`);
          expect(releasedAfter.toBigInt()).to.equal(releasedBefore.add(releasable).toBigInt());
          expect(releasedAfter.toBigInt()).to.be.lte(allocated.toBigInt());
        } else {
          console.log(`Month ${month}, address ${getWalletName(wallet.address)}, releasable: ${releasable.toBigInt()}`);
          expect(releasable.toBigInt()).to.equal(0);
        }
      }
    }
  });
});

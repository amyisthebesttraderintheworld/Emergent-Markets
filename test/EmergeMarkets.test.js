const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Emerge Markets System", function () {
    let RealWorldToken, InternalToken, Treasury, Marketplace;
    let realWorldToken, internalToken, treasury, marketplace;
    let owner, bob, lisa, addrs;
    let initialAssetPrice;

    beforeEach(async function () {
        // Get signers
        [owner, bob, lisa, ...addrs] = await ethers.getSigners();

        // Deploy RealWorldEmergeToken
        RealWorldToken = await ethers.getContractFactory("RealWorldEmergeToken");
        realWorldToken = await RealWorldToken.deploy();

        // Deploy InternalEmergeToken
        InternalToken = await ethers.getContractFactory("InternalEmergeToken");
        internalToken = await InternalToken.deploy();

        // Deploy Treasury
        Treasury = await ethers.getContractFactory("Treasury");
        treasury = await Treasury.deploy(await realWorldToken.getAddress());

        // Deploy Marketplace
        initialAssetPrice = ethers.parseEther("0.1"); // 0.1 tokens per asset
        Marketplace = await ethers.getContractFactory("Marketplace");
        marketplace = await Marketplace.deploy(
            await internalToken.getAddress(),
            await treasury.getAddress(),
            initialAssetPrice
        );

        // Set up contract relationships
        await realWorldToken.setTreasury(await treasury.getAddress());
        await internalToken.setMarketplace(await marketplace.getAddress());
        await treasury.setMarketplace(await marketplace.getAddress());

        // Add Bob and Lisa as participants
        await internalToken.addParticipant(bob.address);
        await internalToken.addParticipant(lisa.address);

        // Mint initial internal tokens to Bob and Lisa
        const initialBalance = ethers.parseEther("1000");
        await internalToken.connect(marketplace).mint(bob.address, initialBalance);
        await internalToken.connect(marketplace).mint(lisa.address, initialBalance);
    });

    describe("System Setup", function () {
        it("Should set correct initial states", async function () {
            expect(await internalToken.isParticipant(bob.address)).to.be.true;
            expect(await internalToken.isParticipant(lisa.address)).to.be.true;
            expect(await internalToken.marketplace()).to.equal(await marketplace.getAddress());
            expect(await realWorldToken.treasury()).to.equal(await treasury.getAddress());
        });

        it("Should set correct initial balances", async function () {
            const bobBalance = await internalToken.balanceOf(bob.address);
            const lisaBalance = await internalToken.balanceOf(lisa.address);
            expect(bobBalance).to.equal(ethers.parseEther("1000"));
            expect(lisaBalance).to.equal(ethers.parseEther("1000"));
        });
    });

    describe("Trading Mechanics", function () {
        it("Should allow Bob to buy assets", async function () {
            const assetToBuy = "A";
            const amount = 5;
            const totalCost = initialAssetPrice * BigInt(amount);

            await marketplace.connect(bob).buyAsset(ethers.encodeBytes32String(assetToBuy)[0], amount);

            const bobAssetBalance = await marketplace.getAssetBalance(bob.address, ethers.encodeBytes32String(assetToBuy)[0]);
            expect(bobAssetBalance).to.equal(amount);

            // Check internal token balance was reduced
            const expectedBalance = ethers.parseEther("1000") - totalCost;
            expect(await internalToken.balanceOf(bob.address)).to.equal(expectedBalance);
        });

        it("Should allow Lisa to sell assets", async function () {
            // First, Lisa needs to buy some assets
            const assetToTrade = "B";
            const amount = 5;
            await marketplace.connect(lisa).buyAsset(ethers.encodeBytes32String(assetToTrade)[0], amount);

            // Now she can sell them
            await marketplace.connect(lisa).sellAsset(ethers.encodeBytes32String(assetToTrade)[0], amount);

            const lisaAssetBalance = await marketplace.getAssetBalance(lisa.address, ethers.encodeBytes32String(assetToTrade)[0]);
            expect(lisaAssetBalance).to.equal(0);

            // Check internal token balance is back to initial amount
            expect(await internalToken.balanceOf(lisa.address)).to.equal(ethers.parseEther("1000"));
        });
    });

    describe("Token Minting/Burning Mechanism", function () {
        it("Should mint real-world tokens when internal tokens are minted", async function () {
            const internalAmount = ethers.parseEther("100");
            const expectedRealWorldAmount = internalAmount / 100n; // 100:1 ratio

            // Simulate trading that results in minting
            await marketplace.connect(lisa).buyAsset(ethers.encodeBytes32String("C")[0], 1000);
            await marketplace.connect(bob).sellAsset(ethers.encodeBytes32String("C")[0], 1000);

            // Check real-world token supply
            expect(await realWorldToken.balanceOf(await treasury.getAddress())).to.be.above(0n);
        });

        it("Should burn real-world tokens when internal tokens are burned", async function () {
            // First mint some real-world tokens
            const initialTrade = 1000;
            await marketplace.connect(lisa).buyAsset(ethers.encodeBytes32String("D")[0], initialTrade);
            await marketplace.connect(bob).sellAsset(ethers.encodeBytes32String("D")[0], initialTrade);

            const initialSupply = await realWorldToken.balanceOf(await treasury.getAddress());

            // Now do trades that result in burning
            await marketplace.connect(bob).buyAsset(ethers.encodeBytes32String("E")[0], initialTrade);

            // Check real-world token supply has decreased
            expect(await realWorldToken.balanceOf(await treasury.getAddress())).to.be.below(initialSupply);
        });
    });

    describe("Security Features", function () {
        it("Should prevent non-participants from trading", async function () {
            const nonParticipant = addrs[0];
            await expect(
                marketplace.connect(nonParticipant).buyAsset(ethers.encodeBytes32String("F")[0], 1)
            ).to.be.revertedWith("Only participants can perform this action");
        });

        it("Should prevent direct token transfers between participants", async function () {
            await expect(
                internalToken.connect(bob).transfer(lisa.address, ethers.parseEther("1"))
            ).to.be.revertedWith("Only marketplace can perform this action");
        });

        it("Should allow owner to pause trading", async function () {
            await marketplace.pause();
            await expect(
                marketplace.connect(bob).buyAsset(ethers.encodeBytes32String("G")[0], 1)
            ).to.be.revertedWith("Paused");
        });
    });
});

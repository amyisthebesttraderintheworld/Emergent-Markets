// Deployment script for Emerge Markets contracts

async function main() {
    const [deployer, bob, lisa] = await ethers.getSigners();
    console.log("Deploying contracts with account:", deployer.address);

    // Deploy RealWorldEmergeToken
    const RealWorldEmergeToken = await ethers.getContractFactory("RealWorldEmergeToken");
    const realWorldToken = await RealWorldEmergeToken.deploy();
    await realWorldToken.waitForDeployment();
    console.log("RealWorldEmergeToken deployed to:", await realWorldToken.getAddress());

    // Deploy InternalEmergeToken
    const InternalEmergeToken = await ethers.getContractFactory("InternalEmergeToken");
    const internalToken = await InternalEmergeToken.deploy();
    await internalToken.waitForDeployment();
    console.log("InternalEmergeToken deployed to:", await internalToken.getAddress());

    // Deploy Treasury with RealWorldEmergeToken address
    const Treasury = await ethers.getContractFactory("Treasury");
    const treasury = await Treasury.deploy(await realWorldToken.getAddress());
    await treasury.waitForDeployment();
    console.log("Treasury deployed to:", await treasury.getAddress());

    // Deploy Marketplace with InternalEmergeToken and Treasury addresses
    const initialAssetPrice = ethers.parseEther("0.1"); // 0.1 internal tokens per asset
    const Marketplace = await ethers.getContractFactory("Marketplace");
    const marketplace = await Marketplace.deploy(
        await internalToken.getAddress(),
        await treasury.getAddress(),
        initialAssetPrice
    );
    await marketplace.waitForDeployment();
    console.log("Marketplace deployed to:", await marketplace.getAddress());

    // Set up contract relationships
    console.log("Setting up contract relationships...");

    // Set Treasury as the controller of RealWorldEmergeToken
    await realWorldToken.setTreasury(await treasury.getAddress());
    console.log("Treasury set as controller of RealWorldEmergeToken");

    // Set Marketplace as the controller of InternalEmergeToken
    await internalToken.setMarketplace(await marketplace.getAddress());
    console.log("Marketplace set as controller of InternalEmergeToken");

    // Set Marketplace as the authorized caller for Treasury
    await treasury.setMarketplace(await marketplace.getAddress());
    console.log("Marketplace set as authorized caller for Treasury");

    // Add Bob and Lisa as participants in the InternalEmergeToken system
    await internalToken.addParticipant(bob.address);
    await internalToken.addParticipant(lisa.address);
    console.log("Added Bob and Lisa as participants");

    // Mint initial internal tokens to Bob and Lisa for testing
    const initialBalance = ethers.parseEther("1000"); // 1000 internal tokens each
    await internalToken.connect(await marketplace.getAddress()).mint(bob.address, initialBalance);
    await internalToken.connect(await marketplace.getAddress()).mint(lisa.address, initialBalance);
    console.log("Minted initial internal tokens to Bob and Lisa");

    console.log("Deployment and setup complete!");
    console.log("\nContract Addresses:");
    console.log("--------------------");
    console.log("RealWorldEmergeToken:", await realWorldToken.getAddress());
    console.log("InternalEmergeToken:", await internalToken.getAddress());
    console.log("Treasury:", await treasury.getAddress());
    console.log("Marketplace:", await marketplace.getAddress());
    console.log("\nParticipant Addresses:");
    console.log("--------------------");
    console.log("Bob:", bob.address);
    console.log("Lisa:", lisa.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });

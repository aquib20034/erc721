const fs = require('fs');
const { ethers } = require('hardhat');
async function main() {
    const Cntrct = await ethers.getContractFactory("BaguetteBoys");
    const cntrct = await Cntrct.deploy();
    console.log('Deploying...');
    await cntrct.deployed();
    console.log("Contract deployed to:", cntrct.address);

    const addresses = {
        implementation: cntrct.address
    };

    try { 
        await run('verify', { address: addresses.implementation });
    } catch (e) {}

    fs.writeFileSync('deployment-address.json', JSON.stringify(addresses));


  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
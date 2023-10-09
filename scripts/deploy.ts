import hre from "hardhat";

type Time = number;

const agentsNftContractDeployment =
  "0xdE7a2f5e3259b25737f99eEab74C110236a679FD";

async function sleep(ms: Time) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function main() {
  //deploy the XAgentsNFT contract
  console.log("-----------------------------");
  console.log("Deploying XAgentsNft contract");

  const nftContract = await hre.ethers.deployContract("XAgentsNFT");
  await nftContract.waitForDeployment();
  console.log(`XAgentsNFT contract deployed at: ${nftContract.target}`);

  //deploy the Marketplace contract
  console.log("-----------------------------");
  console.log("Deploying Marketplace contract");

  const marketplaceContract = await hre.ethers.deployContract("Marketplace");
  await marketplaceContract.waitForDeployment();
  console.log(
    `Marketplace contract deployed at: ${marketplaceContract.target}`
  );

  //deploy the AgentsDAO contract
  console.log("-----------------------------");
  console.log("Deploying AgentsDAO contract");

  const amount = hre.ethers.parseEther("0.3");
  const agentsDaoContract = await hre.ethers.deployContract(
    "AgentsDAO",
    [marketplaceContract.target, agentsNftContractDeployment],
    { value: amount }
  );
  await agentsDaoContract.waitForDeployment();
  console.log(`AgentsDAO Contract deployed at: ${agentsDaoContract.target}`);

  await sleep(30 * 1000);

  //verify XagentsNFT contract
  await hre.run("verify:verify", {
    address: nftContract.target,
    constructorArguments: [],
  });

  //verify Marketplace contract
  await hre.run("verify:verify", {
    address: marketplaceContract.target,
    constructorArguments: [],
  });

  //verify AgentsDAO contract
  await hre.run("verify:verify", {
    address: agentsDaoContract.target,
    constructorArguments: [
      marketplaceContract.target,
      agentsNftContractDeployment,
    ],
  });
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

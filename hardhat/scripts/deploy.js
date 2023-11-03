const hre=require("hardhat");

async function sleep(ms){
  await new Promise((resolve)=>setTimeout(resolve,ms))
}

async function main(){

  //This token contract mints a token which is then used to add liquidity
  const tokenContract=await hre.ethers.deployContract("Token");
  await tokenContract.waitForDeployment();
  console.log("Token contract deployed to:",tokenContract.target);

  const jasiSwap=await hre.ethers.deployContract("JasiSwap",[tokenContract.target]);
  await jasiSwap.waitForDeployment();
  console.log("DEX contract deployed to:",jasiSwap.target);

  //This lets etherscan catch up with all deployments
  await sleep(30*1000);

  //Verifying contracts
  await hre.run("verify:verify",{
    address:tokenContract.target,
    constructorArguments:[]
  });

  await hre.run("verify:verify",{
    address:jasiSwap.target,
    constructorArguments:[tokenContract.target]
  });

}

main()
      .then(()=>process.exit(0))
      .catch((e)=>{
        console.error(e);
        process.exit(1);
      })
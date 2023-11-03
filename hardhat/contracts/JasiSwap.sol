//SPDX-License-Identifier:MIT

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract JasiSwap is ERC20{
    address public tokenAddress;

    constructor(address token)ERC20("ETH Liquidity Provider Token","ELPT"){
        require(token!=address(0),"invalid address porvided");
    }
    function addLiquidity(uint256 amountToken)public payable returns(uint256){
        uint256 tokenReserve=getSupply();
        uint256 lpTokensToMint;
        ERC20 token=ERC20(tokenAddress);
        if(tokenReserve==0){
            uint256 initialEthReserve=address(this).balance;
            token.transferFrom(msg.sender,address(this),amountToken);
            //during the initial addition of liquidity,LP tokens minted is equivalent to the eth reserve balance
            lpTokensToMint=initialEthReserve;
            //Minting LP tokens to the provider's address
            _mint(msg.sender,lpTokensToMint);
            return lpTokensToMint;
        }
            //ETH reserve prior to this liquidity
            uint256 ethReservePriorFnCall=address(this).balance-msg.value;

            //The amount of token amount to be deposited that keeps the existing proportionality of ETH/Token 
            uint256 proportionateTokenAmount=(msg.value * tokenReserve)/ethReservePriorFnCall;
            require(amountToken>=proportionateTokenAmount,"need more token amount to add into liquidity");

            token.transferFrom(msg.sender,address(this),proportionateTokenAmount);

            //calculating the amount of LP tokens to mint
            lpTokensToMint=(totalSupply() * msg.value)/ethReservePriorFnCall;
            _mint(msg.sender,lpTokensToMint);
        
        return lpTokensToMint;
    }
    function removeLiquidity(uint256 lpTokenMinted)public returns(uint256,uint256) {

        require(lpTokenMinted>0,"there is no minted LP tokens");

        uint256 totalEthReserve=address(this).balance;

        //Total Supply here is the total supply of minted LP tokens
        uint256 totalLPTokenSupply=totalSupply();

        uint256 ethToReturn=(lpTokenMinted*totalEthReserve)/totalLPTokenSupply;

        uint256 tokenToreturn=(getSupply() * lpTokenMinted)/totalLPTokenSupply;

        //Burn the LP token from the msg.sender
        _burn(msg.sender,lpTokenMinted);

        payable(msg.sender).transfer(ethToReturn);
        ERC20(tokenAddress).transfer(msg.sender,tokenToreturn);

        return(ethToReturn,tokenToreturn);
    }

    //This function helps to calculate the expected output token amount for an input amount ,with fee
    function getOutputAmountFromSwap(
        uint256 inputTokenAmount,
        uint256 inputTokenReserve,
        uint256 outputTokenReserve
        )public pure returns(uint256){
            require(inputTokenReserve>0 && outputTokenReserve>0,"Reserves can't be empty");
            uint256 inputAmountWithFee=inputTokenAmount*99;
            uint256 numerator=outputTokenReserve*inputAmountWithFee;
            uint256 denominator=(inputTokenReserve*100)+inputTokenAmount;
            return numerator/denominator;
    }

    function ethToTokenSwap(uint256 minTokenOnSwap)public payable{
        uint256 outputTokenReserve=getSupply();

        //Calculating the the token that we get from swapping Eth
        uint256 actualTokenOnSwap=getOutputAmountFromSwap(
            msg.value,
            address(this).balance-msg.value,
            outputTokenReserve
        );

        require(actualTokenOnSwap>=minTokenOnSwap,"actual token on swap is less than min token on swap");

        ERC20(tokenAddress).transfer(msg.sender,actualTokenOnSwap);
    }

    function tokenToEthSwap(
        uint256 tokensToSwap,
        uint256 minEthOnSwap
    )public {
        uint256 inputTokenReserve=getSupply();
        uint256 actualEthOnSwap=getOutputAmountFromSwap(
            tokensToSwap,
            inputTokenReserve,
            address(this).balance
        );

        require(actualEthOnSwap>=minEthOnSwap,"Eth on swap must be greater than minimum value");

        //transferring tokens for swap to the contract
        ERC20(tokenAddress).transferFrom(msg.sender,address(this),tokensToSwap);
        //Sending the Eth obtained througj swap to the user 
        payable(msg.sender).transfer(actualEthOnSwap);
    }

    function getSupply()public view returns(uint256){
        return ERC20(tokenAddress).balanceOf(address(this));
    }

}
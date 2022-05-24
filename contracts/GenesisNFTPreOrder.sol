// SPDX-License-Identifier: MIT

/**
 *****    .*****************************************     *****.
  *****     ***************************************    .*****
   ******    ******                                   ******
     *****     *****                                ******        ***       ****    ***,      **********      ****      ***********       .***         .***          ***       ***
      ******    ******                             *****           ***.    ****     ***,      ***     ***.    ****      ***      ****     .***        ******         *****     ***
        *****     **************************,    ******             ***,  ***       ***,      ***    ****     ****      ***       ****    .***       **** ***        *** ****  ***
         ,*****    ************************     *****                *******        ***,      ********.       ****      ***       ***     .***      ***,   ***       ***   *******
           *****     *****                    ******                  *****         ***,      ***   ***,      ****      ***     ****,     .***     ************      ***     *****
            ,*****    ******                ,*****                     .**          ***,      ***    ****     ****      **********        .***    ***        ***     ***       ***
              *****     ******             ******
                *****     ***********    ,*****
                 ******    ********     ******
                   *****     *****    ******                       **********     ****    ****      ,**********     ***       ***.          **.          **        ***        **********      **********
                    ******    **     *****                         ***.            **** ****      .****      *      ***       ***.        .****,         *****     ***      ****      *,      ***.
                      *****        ******                          *********         ******       ***               *************.       ,*******        *******   ***     ****               *********
                       .*****     *****                            *********         ******       ***               *************.      ****  ****       ***  ********     ***.     *****     *********
                         *****. ******                             ***.            **** ****      ****.             ***       ***.     ************      ***     *****      ****      ***     ***.
                          .*********                               **********     ****    ****      ***********     ***       ***.    ***.       ***     ***       ***        ***********     **********
                            *******
                              ***
 */

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract GenesisNFTPreOrder is Ownable {
    address payable treasury;
    uint256 maxPreOrders = 300;
    // Default cost for minting one NFT in the Genesis drop
    uint256 public mintPrice = 220000000000000000;

    mapping(address => uint256) preOrders;
    mapping(uint256 => address) preOrderAddresses;

    using Counters for Counters.Counter;
    Counters.Counter public numBuyers;
    uint256 public numOrders;

    /**
     * @dev Set the default ERC20Token address, Viridian NFT address, forwarder for gasless, and treasury for royalty payments.
     */
    constructor(address payable _treasury) {
        require(_treasury != address(0), "Token address must not be the 0 address");

        treasury = _treasury;
    }

    function preOrder(uint256 numPreOrders) payable public {
        require(numPreOrders * mintPrice == msg.value, "Must pay correct amount of ETH to mint.");
        require(numOrders + numPreOrders <= maxPreOrders, "Cannot mint more than the max allocated pre-orders");

        preOrders[msg.sender] = numPreOrders;

        numOrders += numPreOrders;
        if (preOrders[msg.sender] == 0) {
            numBuyers.increment();
            uint256 curOrderIndex = numBuyers.current();
            preOrderAddresses[curOrderIndex] = msg.sender;
            preOrders[msg.sender] = numPreOrders;
        }
        else {
            preOrders[msg.sender] += numPreOrders;
        }
        
    }

    function preOrderAddressList() external view onlyOwner() returns (address[] memory addrs) {
        for(uint256 i = 1; i <= numBuyers.current(); i++) {
            addrs[i - 1] = preOrderAddresses[i];
        }
    }

    function preOrderAmountList() external view onlyOwner() returns (uint256[] memory amts) {
        for(uint256 i = 1; i <= numBuyers.current(); i++) {
            amts[i - 1] = preOrders[preOrderAddresses[i]];
        }
    }
}
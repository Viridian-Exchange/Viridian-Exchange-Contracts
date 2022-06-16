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

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
* Viridian NFT
*
* This contract is designed to be used on our genesis Ethereum mint and future drops on the same contract, it is extremely gas efficient for minting multiple packs.
*
* If this contract can be upgradable and/or be upgradable it could be converted to our main infrastructure contract.
*/
contract UpgradeTest is Initializable {
    // /**
    //  * @dev Set the original default opened and unopenend base URI. Also set the forwarder for gaseless and the treasury address.
    //  */
    //  function initialize() public initializer {
    // }
}

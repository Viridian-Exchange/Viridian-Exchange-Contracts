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

/**
 * Generator and verifier for Proofs Of Integrity.
 */ 
contract ProofOfIntegrity {

    constructor() {}

    /**
     * @dev Generates a Proof Of Integrity as the keccak256 hash of a human readable {base} and a randomly pre-generated number {salt}.
     */
    function generateProof(string memory base, uint256 salt) public pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(base, salt)));
    }

    /**
     * @dev Verifies a Proof Of Integrity {proof} against a human readable {base} and a randomly pre-generated number {salt}.
     */
    function verifyProof(uint256 tokenId, string memory base, uint256 salt) public pure returns (bool) {
        return tokenId == generateProof(base, salt);
    }
    
}
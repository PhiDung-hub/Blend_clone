// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import { ERC721 } from "@solmate/tokens/ERC721.sol";
import { Blend } from "~/BlurLending/Blend.sol";
import { Lien } from "~/lib/Blend/Structs.sol";

contract BlendRefinanceAuction is Test {
  uint256 mainnetFork;
  Blend constant BLEND_CONTRACT = Blend(payable(0x29469395eAf6f95920E59F858042f0e28D98a20B));

  string MAINNET_RPC_URL = vm.envString("FORK_URL");

  function setUp() public {
    mainnetFork = vm.createFork(MAINNET_RPC_URL);
  }

  // function logLienHash() public view {
  //   bytes32 lienHash = keccak256(
  //     abi.encode(
  //       Lien({
  //         lender: 0xCBB0Fe555F61D23427740984325b4583A4A34C82,
  //         borrower: 0x7Df70b612040c682d1cb2e32017446e230FcD747,
  //         collection: ERC721(0xBd3531dA5CF5857e7CfAA92426877b022e612cf8),
  //         tokenId: 6371,
  //         amount: 4335522362679578673,
  //         startTime: 1698118210,
  //         rate: 0,
  //         auctionStartBlock: 0,
  //         auctionDuration: 9000
  //       })
  //     )
  //   );
  //   console.logBytes32(lienHash);
  // }

  function testRefinanceAuctionLien_104759() public {
    // NOTE: IMMUTABLE lien details
    // Dune query for lienState: https://dune.com/queries/3126370
    uint256 LIEN_ID = 104759;
    uint256 TOKEN_ID = 6371;
    ERC721 COLLECTION = ERC721(0xBd3531dA5CF5857e7CfAA92426877b022e612cf8);
    address BORROWER = 0x7Df70b612040c682d1cb2e32017446e230FcD747;
    address INTERACTOR = 0xCBB0Fe555F61D23427740984325b4583A4A34C82;

    vm.selectFork(mainnetFork);
    vm.rollFork(18410847); // NOTE: 300 blocks (1 hour) after auction start -> MAX RATE ~20 bps

    vm.startPrank(INTERACTOR);

    /////////////////////////////////////
    ///// STEP 1: Refinance Auction /////
    Lien memory originalLien = Lien({
      lender: 0xfD1CB5F8590e40450eb83F3E25e21B24175b140E, // PREVIOUS LENDER
      borrower: BORROWER,
      collection: COLLECTION,
      tokenId: TOKEN_ID,
      amount: 4335522362679578673,
      startTime: 1697947739,
      rate: 0,
      auctionStartBlock: 18410547,
      auctionDuration: 9000
    });

    BLEND_CONTRACT.refinanceAuction(originalLien, LIEN_ID, 0); // newRate = 0

    Lien memory newLien = Lien({
      lender: INTERACTOR,
      borrower: BORROWER,
      collection: COLLECTION,
      tokenId: TOKEN_ID,
      amount: 4335522362679578673,
      startTime: 1698038303, // timestamp of block 18410847
      rate: 0,
      auctionStartBlock: 0,
      auctionDuration: 9000
    });

    // assert new lien hash
    assertEq(BLEND_CONTRACT.liens(104759), keccak256(abi.encode(newLien)));
    //////////// END STEP 1 /////////////
    /////////////////////////////////////

    /////////////////////////////////////
    /////// STEP 2: Start Auction ///////
    BLEND_CONTRACT.startAuction(newLien, LIEN_ID);

    Lien memory auctionedLien = Lien({
      lender: INTERACTOR,
      borrower: BORROWER,
      collection: COLLECTION,
      tokenId: TOKEN_ID,
      amount: 4335522362679578673,
      startTime: 1698038303, // timestamp of block 18410847
      rate: 0,
      auctionStartBlock: 18410847,
      auctionDuration: 9000
    });

    // assert auctioned lien hash
    assertEq(BLEND_CONTRACT.liens(104759), keccak256(abi.encode(auctionedLien)));
    //////////// END STEP 2 /////////////
    /////////////////////////////////////

    vm.stopPrank();
  }
}

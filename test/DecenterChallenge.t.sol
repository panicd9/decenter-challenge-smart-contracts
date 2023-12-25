pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {DecenterChallenge} from "../src/DecenterChallenge.sol";
import {DssCdpManagerMock} from "./mocks/DssCdpManagerMock.sol";
import {VatMock} from "./mocks/VatMock.sol";
import {console} from "forge-std/console.sol";

contract DecenterChallengeTest is Test {
    DecenterChallenge dc;
    DssCdpManagerMock manager;
    VatMock vat;

    address public USER = makeAddr("user");
    uint256 RATE_TEST = 1.1 * 10 ** 27;
    uint256 DEBT_TEST = 1 ether;
    uint256 COLLATERAL_TEST = 10 ether;

    function setUp() external {
        vat = new VatMock();
        manager = new DssCdpManagerMock(address(vat));
        dc = new DecenterChallenge();

        dc.setManager(address(manager));
        dc.setVat(address(vat));
    }

    function test1() public {
        vm.startPrank(USER);
        console.log("User address", USER);

        manager.open(bytes32("ETH-A"), USER);

        vat.setIlks(bytes32("ETH-A"), DEBT_TEST, RATE_TEST);
        vat.setUrns(bytes32("ETH-A"), manager.urns(1), COLLATERAL_TEST, DEBT_TEST);

        (uint256 ink, uint256 art) = vat.urns(bytes32("ETH-A"), USER);
        console.log("ink: ", ink);
        console.log("art: ", art);

        (
            address urn,
            address owner,
            address userAddr,
            bytes32 ilk,
            uint256 collateral,
            uint256 debt,
            uint256 debtWithRate
        ) = dc.getCdpInfoWithRate(1);

        vm.stopPrank();

        assertEq(debtWithRate, 1.1 * 10 ** 27); // 1.1 ether represented in RAY

        console.log("urn", urn);
        console.log("owner", owner);
        console.log("userAddr", userAddr);
        console.logBytes32(ilk);
        console.log("collateral", collateral);
        console.log("debt", debt);
        console.log("debtWithRate", debtWithRate);
    }
}

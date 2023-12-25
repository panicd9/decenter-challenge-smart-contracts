// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {console} from "forge-std/console.sol";

contract DSMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x);
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x);
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x <= y ? x : y;
    }

    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x >= y ? x : y;
    }

    function imin(int256 x, int256 y) internal pure returns (int256 z) {
        return x <= y ? x : y;
    }

    function imax(int256 x, int256 y) internal pure returns (int256 z) {
        return x >= y ? x : y;
    }

    uint256 constant WAD = 10 ** 18;
    uint256 constant RAY = 10 ** 27;

    function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }

    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }

    function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, WAD), y / 2) / y;
    }

    function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

    function rpow(uint256 x, uint256 n) internal pure returns (uint256 z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }
}

contract Vat {
    struct Urn {
        uint256 ink;
        uint256 art;
    }

    struct Ilk {
        uint256 Art;
        uint256 rate;
        uint256 spot;
        uint256 line;
        uint256 dust;
    }

    mapping(bytes32 => mapping(address => Urn)) public urns;
    mapping(bytes32 => Ilk) public ilks;
}

abstract contract Manager {
    function ilks(uint256) public view virtual returns (bytes32);
    function owns(uint256) public view virtual returns (address);
    function urns(uint256) public view virtual returns (address);
}

abstract contract DSProxy {
    function owner() public view virtual returns (address);
}

contract VaultInfo is DSMath {
    Manager manager = Manager(0x5ef30b9986345249bc32d8928B7ee64DE9435E39);
    Vat vat = Vat(0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B);

    function _getProxyOwner(address owner) external view returns (address userAddr) {
        DSProxy proxy = DSProxy(owner);
        userAddr = proxy.owner();
    }

    function getCdpInfo(uint256 _cdpId)
        external
        view
        returns (address urn, address owner, address userAddr, bytes32 ilk, uint256 collateral, uint256 debt)
    {
        ilk = manager.ilks(_cdpId);
        urn = manager.urns(_cdpId);
        owner = manager.owns(_cdpId);
        userAddr = address(0);
        try this._getProxyOwner(owner) returns (address user) {
            userAddr = user;
        } catch {}

        (collateral, debt) = vat.urns(ilk, urn);
    }
}

contract DecenterChallenge is VaultInfo {
    function getCdpInfoWithRate(uint256 _cdpId)
        external
        view
        returns (
            address urn,
            address owner,
            address userAddr,
            bytes32 ilk,
            uint256 collateral,
            uint256 debt,
            uint256 debtWithRate
        )
    {
        ilk = manager.ilks(_cdpId);
        urn = manager.urns(_cdpId);
        owner = manager.owns(_cdpId);
        userAddr = address(0);
        try this._getProxyOwner(owner) returns (address user) {
            userAddr = user;
        } catch {}

        console.log("dc ilk: ");
        console.logBytes32(ilk);
        console.log("dc urn", urn);
        console.log("dc owner", owner);
        console.log("dc userAddr", userAddr);

        (collateral, debt) = vat.urns(ilk, urn);

        console.log("dc collateral", collateral);
        console.log("dc debt", debt);

        (, uint256 rate,,,) = vat.ilks(ilk);
        debtWithRate = wmulRayToRay(debt, rate); // RAY
    }

    function setManager(address _manager) external {
        manager = Manager(_manager);
    }

    function setVat(address _vat) external {
        vat = Vat(_vat);
    }

    function wmulRayToRay(uint256 wad, uint256 ray) internal pure returns (uint256) {
        return (wad * ray + 5 * 10 ** 17) / 10 ** 18;
    }
}

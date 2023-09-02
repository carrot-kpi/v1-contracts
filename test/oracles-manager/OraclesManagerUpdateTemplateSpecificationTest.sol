pragma solidity 0.8.19;

import {BaseTestSetup} from "../commons/BaseTestSetup.sol";
import {OraclesManager1} from "../../contracts/oracles-managers/OraclesManager1.sol";
import {IOraclesManager1} from "../../contracts/interfaces/oracles-managers/IOraclesManager1.sol";
import {Template} from "../../contracts/interfaces/IBaseTemplatesManager.sol";
import {OraclesManager1Harness} from "../harnesses/OraclesManager1Harness.sol";
import {Clones} from "oz/proxy/Clones.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title Oracles manager update template specification test
/// @dev Tests template specification update in oracles manager.
/// @author Federico Luzzi - <federico.luzzi@protonmail.com>
contract OraclesManagerUpdateTemplateSpecificationTest is BaseTestSetup {
    function testNonOwner() external {
        vm.prank(address(1));
        vm.expectRevert("Ownable: caller is not the owner");
        oraclesManager.updateTemplateSpecification(0, "");
    }

    function testNonExistentTemplate() external {
        vm.expectRevert(abi.encodeWithSignature("NonExistentTemplate()"));
        oraclesManager.updateTemplateSpecification(0, "a");
    }

    function testEmptySpecification() external {
        vm.expectRevert(abi.encodeWithSignature("InvalidSpecification()"));
        oraclesManager.updateTemplateSpecification(0, "");
    }

    function testSuccess() external {
        string memory _oldSpecification = "a";
        oraclesManager.addTemplate(address(2), _oldSpecification);
        uint256 _templateId = oraclesManager.templatesAmount();
        Template memory _template = oraclesManager.template(_templateId);
        assertEq(_template.id, _templateId);
        assertEq(_template.specification, _oldSpecification);
        string memory _newSpecification = "b";
        oraclesManager.updateTemplateSpecification(_templateId, _newSpecification);
        _template = oraclesManager.template(_templateId);
        assertEq(_template.id, _templateId);
        assertEq(_template.specification, _newSpecification);
    }

    function testNonOwnerSpecificVersion() external {
        vm.prank(address(1));
        vm.expectRevert("Ownable: caller is not the owner");
        oraclesManager.updateTemplateSpecification(0, 0, "");
    }

    function testNonExistentTemplateSpecificVersion() external {
        vm.expectRevert(abi.encodeWithSignature("NonExistentTemplate()"));
        oraclesManager.updateTemplateSpecification(0, 0, "a");
    }

    function testNonExistentVersionSpecificVersion() external {
        vm.expectRevert(abi.encodeWithSignature("NonExistentTemplate()"));
        oraclesManager.updateTemplateSpecification(
            1,
            200, // non existent version
            "a"
        );
    }

    function testEmptySpecificationSpecificVersion() external {
        vm.expectRevert(abi.encodeWithSignature("InvalidSpecification()"));
        oraclesManager.updateTemplateSpecification(0, 1, "");
    }

    function testSuccessPastVersion() external {
        assertEq(oraclesManager.templatesAmount(), 1);

        string memory _oldSpecification = "a";
        oraclesManager.addTemplate(address(2), _oldSpecification);
        uint256 _templateId = oraclesManager.templatesAmount();
        Template memory _template = oraclesManager.template(_templateId);
        assertEq(_template.id, _templateId);
        assertEq(_template.version, 1);
        assertEq(_template.specification, _oldSpecification);

        // add an additional template
        string memory _upgradedSpecification = "b";
        oraclesManager.upgradeTemplate(_templateId, address(3), _upgradedSpecification);
        // templates amount is 2 because the test templates manager start with
        // one template being present
        assertEq(oraclesManager.templatesAmount(), 2);
        Template memory _upgradedTemplate = oraclesManager.template(_templateId);
        assertEq(_upgradedTemplate.id, _templateId);
        assertEq(_upgradedTemplate.version, 2);
        assertEq(_upgradedTemplate.specification, _upgradedSpecification);

        string memory _newSpecification = "new";
        oraclesManager.updateTemplateSpecification(_templateId, 1, _newSpecification);
        Template memory _updatedTemplate = oraclesManager.template(_templateId, 1);
        Template memory _upgradedTemplatePostUpdate = oraclesManager.template(_templateId, 2);

        // check that the upgraded template was left unchanged
        assertEq(_upgradedTemplate.id, _upgradedTemplatePostUpdate.id);
        assertEq(_upgradedTemplate.version, _upgradedTemplatePostUpdate.version);
        assertEq(_upgradedTemplate.specification, _upgradedTemplatePostUpdate.specification);

        // check that the updated template was in fact updated
        assertEq(_updatedTemplate.id, 2);
        assertEq(_updatedTemplate.version, 1);
        assertEq(_updatedTemplate.specification, _newSpecification);
    }

    function testSuccessExplicitLatestVersion() external {
        OraclesManager1Harness oraclesManager = new OraclesManager1Harness(
            address(factory)
        );

        assertEq(oraclesManager.templatesAmount(), 0);

        address _templateAddress = address(1);
        string memory _specification = "a";
        oraclesManager.addTemplate(_templateAddress, _specification);

        assertEq(oraclesManager.templatesAmount(), 1);

        Template memory _template = oraclesManager.template(1);
        assertEq(_template.id, 1);
        assertEq(_template.addrezz, _templateAddress);
        assertEq(_template.specification, _specification);

        string memory _newSpecification = "new";
        oraclesManager.updateTemplateSpecification(_template.id, _template.version, _newSpecification);

        // the harness function explicitly reads from the latest version
        // templates array
        Template memory _latestVersionTemplate = oraclesManager.exposedLatestVersionStorageTemplate(_template.id);
        assertEq(_latestVersionTemplate.specification, _newSpecification);

        // the template reading function operates on the template by id and
        // version array, so with the assertion above we check that both
        // templates were updated correctly.
        Template memory _templateByIdAndVersion = oraclesManager.template(_template.id, _template.version);
        assertEq(_templateByIdAndVersion.specification, _newSpecification);
    }
}

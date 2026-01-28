// SPDX-License-Identifier: DIODE
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "./Assert.sol";
import "../contracts/ZTNAOrganisation.sol";
import "../contracts/ZTNAPerimeterRegistry.sol";
import "../contracts/ZTNAPerimeterContract.sol";

contract ZTNAOrganisationTest is Test {
    ZTNAPerimeterRegistry private registry;

    address private testOwner;
    address private admin1;
    address private admin2;
    address private member1;
    address private member2;
    address private nonMember;

    function setUp() public {
        testOwner = address(this);
        admin1 = address(0x1001);
        admin2 = address(0x1002);
        member1 = address(0x2001);
        member2 = address(0x2002);
        nonMember = address(0x9999);

        // Deploy the registry which also deploys the organisation implementation
        registry = new ZTNAPerimeterRegistry();
    }

    // ======== Helper Functions ========

    function createOrg(string memory name, string memory desc) internal returns (ZTNAOrganisation) {
        address orgAddr = registry.CreateOrganisation(name, desc);
        return ZTNAOrganisation(orgAddr);
    }

    // ======== Use Case 1: Users can create new organizations ========

    function testCreateOrganisation() public {
        ZTNAOrganisation org = createOrg("Test Org", "A test organisation");

        // Verify the organisation was created with correct data
        Assert.equal(org.name(), "Test Org", "Organisation name should match");
        Assert.equal(org.description(), "A test organisation", "Organisation description should match");
        Assert.equal(org.owner(), testOwner, "Creator should be the owner");
        Assert.greaterThan(org.createdAt(), uint256(0), "Created time should be set");
    }

    function testCreateOrganisationViaRegistry() public {
        uint256 countBefore = registry.GetOwnOrganisationCount();

        address orgAddr = registry.CreateOrganisation("Registry Test Org", "Created via registry");

        uint256 countAfter = registry.GetOwnOrganisationCount();
        Assert.equal(countAfter, countBefore + 1, "Organisation count should increase");

        address retrievedOrg = registry.GetOwnOrganisation(countAfter - 1);
        Assert.equal(retrievedOrg, orgAddr, "Retrieved org should match created org");
    }

    function testCreateOrganisationWithDefaultName() public {
        address orgAddr = registry.CreateOrganisation();
        ZTNAOrganisation org = ZTNAOrganisation(orgAddr);

        // Default name includes the count - just verify it's not empty
        Assert.notEqual(bytes(org.name()).length, 0, "Default name should be set");
    }

    function testUserCanOwnMultipleOrganisations() public {
        createOrg("Org 1", "First org");
        createOrg("Org 2", "Second org");

        uint256 count = registry.GetOwnOrganisationCount();
        Assert.equal(count, 2, "Owner should have 2 organisations");
    }

    function testDifferentUsersCreateOrganisations() public {
        // Owner creates an org
        ZTNAOrganisation org1 = createOrg("Owner Org", "Owner's org");

        // Admin1 creates an org
        vm.prank(admin1);
        address org2Addr = registry.CreateOrganisation("Admin Org", "Admin's org");
        ZTNAOrganisation org2 = ZTNAOrganisation(org2Addr);

        // Verify each user owns their org
        Assert.equal(org1.owner(), testOwner, "Owner should own org1");
        Assert.equal(org2.owner(), admin1, "Admin1 should own org2");
    }

    function testOrganisationIsOwnProxy() public {
        // Create two organisations and verify they are separate contracts
        ZTNAOrganisation org1 = createOrg("Org 1", "First");
        ZTNAOrganisation org2 = createOrg("Org 2", "Second");

        // They should have different addresses
        Assert.notEqual(address(org1), address(org2), "Orgs should be different contracts");

        // Each should have its own state
        Assert.equal(org1.name(), "Org 1", "Org1 name should be correct");
        Assert.equal(org2.name(), "Org 2", "Org2 name should be correct");

        // Verify version matches implementation
        Assert.equal(org1.Version(), 202, "Org1 version should be 202");
        Assert.equal(org2.Version(), 202, "Org2 version should be 202");
    }

    // ======== Use Case 2: Organisation Roles (Owner, Admin, Member) ========

    function testAddAdmin() public {
        ZTNAOrganisation org = createOrg("Test Org", "Testing admins");

        // Add admin1 as admin
        org.addAdmin(admin1);

        // Verify admin was added
        Assert.equal(org.isAdmin(admin1), true, "Admin1 should be an admin");
        Assert.equal(org.isOwnerOrAdmin(admin1), true, "Admin1 should be owner or admin");

        // Get all admins
        address[] memory admins = org.getAdmins();
        Assert.equal(admins.length, 1, "Should have 1 admin");
        Assert.equal(admins[0], admin1, "Admin should be admin1");
    }

    function testRemoveAdmin() public {
        ZTNAOrganisation org = createOrg("Test Org", "Testing admin removal");

        org.addAdmin(admin1);
        Assert.equal(org.isAdmin(admin1), true, "Admin1 should be an admin");

        org.removeAdmin(admin1);
        Assert.equal(org.isAdmin(admin1), false, "Admin1 should no longer be an admin");
    }

    function testOnlyOwnerCanAddAdmin() public {
        ZTNAOrganisation org = createOrg("Test Org", "Testing admin permissions");

        // Non-owner tries to add admin - should fail
        vm.prank(nonMember);
        vm.expectRevert();
        org.addAdmin(admin1);
    }

    function testAddMember() public {
        ZTNAOrganisation org = createOrg("Test Org", "Testing members");

        // Owner adds member
        org.addMember(member1);

        Assert.equal(org.isMember(member1), true, "Member1 should be a member");

        address[] memory membersList = org.getMembers();
        Assert.equal(membersList.length, 1, "Should have 1 member");
    }

    function testAdminCanAddMember() public {
        ZTNAOrganisation org = createOrg("Test Org", "Testing admin member management");

        // Owner adds admin
        org.addAdmin(admin1);

        // Admin adds member
        vm.prank(admin1);
        org.addMember(member1);

        Assert.equal(org.isMember(member1), true, "Member1 should be a member");
    }

    function testRemoveMember() public {
        ZTNAOrganisation org = createOrg("Test Org", "Testing member removal");

        org.addMember(member1);
        Assert.equal(org.isMember(member1), true, "Member1 should be a member");

        org.removeMember(member1);
        Assert.equal(org.isMember(member1), false, "Member1 should no longer be a member");
    }

    function testMemberCannotAddMember() public {
        ZTNAOrganisation org = createOrg("Test Org", "Testing member permissions");

        org.addMember(member1);

        // Member tries to add another member - should fail
        vm.prank(member1);
        vm.expectRevert();
        org.addMember(member2);
    }

    function testTransferOwnership() public {
        ZTNAOrganisation org = createOrg("Test Org", "Testing ownership transfer");

        Assert.equal(org.isOwner(testOwner), true, "Original owner should own org");

        org.transferOwnership(admin1);

        Assert.equal(org.isOwner(testOwner), false, "Original owner should no longer own org");
        Assert.equal(org.isOwner(admin1), true, "Admin1 should now own org");
    }

    // ======== Use Case 3: Transfer existing perimeters to organisation ========

    function testTransferPerimeterToOrganisation() public {
        ZTNAOrganisation org = createOrg("Test Org", "Testing perimeter transfer");

        // Create a perimeter directly (owned by this contract)
        registry.CreateFleet("Test Fleet");
        uint256 fleetCount = registry.GetOwnFleetCount();
        ZTNAPerimeterRegistry.FleetMetadataView memory fleet = registry.GetOwnFleet(fleetCount - 1);
        address perimeter = fleet.fleet;

        // Verify we own the perimeter
        ZTNAPerimeterContract perimeterContract = ZTNAPerimeterContract(perimeter);
        Assert.equal(perimeterContract.Operator(), address(this), "We should own the perimeter initially");

        // Two-step transfer process:
        // Step 1: Transfer perimeter ownership to the org contract
        perimeterContract.transferOperator(payable(address(org)));
        Assert.equal(perimeterContract.Operator(), address(org), "Org should now own the perimeter");

        // Step 2: Register the perimeter with the organisation
        org.registerPerimeter(perimeter);

        // Verify the perimeter is tracked in the organisation
        address[] memory perimetersList = org.getPerimeters();
        Assert.equal(perimetersList.length, 1, "Organisation should have 1 perimeter");
        Assert.equal(perimetersList[0], perimeter, "Perimeter should be in organisation");
        Assert.equal(org.hasPerimeter(perimeter), true, "hasPerimeter should return true");
    }

    function testCannotTransferPerimeterYouDontOwn() public {
        ZTNAOrganisation org = createOrg("Test Org", "Testing perimeter transfer auth");

        // Create a perimeter owned by this contract
        registry.CreateFleet("Test Fleet");
        uint256 fleetCount = registry.GetOwnFleetCount();
        ZTNAPerimeterRegistry.FleetMetadataView memory fleet = registry.GetOwnFleet(fleetCount - 1);
        address perimeter = fleet.fleet;

        // Non-owner tries to transfer - should fail
        vm.prank(nonMember);
        vm.expectRevert();
        org.transferPerimeterToOrganisation(perimeter);
    }

    function testRemovePerimeterFromOrganisation() public {
        ZTNAOrganisation org = createOrg("Test Org", "Testing perimeter removal");

        // Create and transfer a perimeter using two-step process
        registry.CreateFleet("Test Fleet");
        uint256 fleetCount = registry.GetOwnFleetCount();
        ZTNAPerimeterRegistry.FleetMetadataView memory fleet = registry.GetOwnFleet(fleetCount - 1);
        address perimeter = fleet.fleet;

        ZTNAPerimeterContract perimeterContract = ZTNAPerimeterContract(perimeter);
        perimeterContract.transferOperator(payable(address(org)));
        org.registerPerimeter(perimeter);

        // Remove the perimeter and transfer to admin1
        org.removePerimeter(perimeter, payable(admin1));

        // Verify admin1 now owns the perimeter
        Assert.equal(perimeterContract.Operator(), admin1, "Admin1 should now own the perimeter");

        // Verify perimeter is no longer in organisation
        address[] memory perimetersList = org.getPerimeters();
        Assert.equal(perimetersList.length, 0, "Organisation should have 0 perimeters");
        Assert.equal(org.hasPerimeter(perimeter), false, "hasPerimeter should return false");
    }

    // ======== Use Case 4: Create perimeters within organisation ========

    function testOwnerCanCreatePerimeterInOrganisation() public {
        ZTNAOrganisation org = createOrg("Test Org", "Testing perimeter creation");

        // Owner creates a perimeter in the organisation
        address perimeter = org.createPerimeter("Org Perimeter");

        // Verify the perimeter was created and is in the organisation
        address[] memory perimetersList = org.getPerimeters();
        Assert.equal(perimetersList.length, 1, "Organisation should have 1 perimeter");
        Assert.equal(perimetersList[0], perimeter, "Perimeter should match");

        // Verify the organisation contract owns the perimeter
        ZTNAPerimeterContract perimeterContract = ZTNAPerimeterContract(perimeter);
        Assert.equal(perimeterContract.Operator(), address(org), "Organisation should own the perimeter");
    }

    function testAdminCanCreatePerimeterInOrganisation() public {
        ZTNAOrganisation org = createOrg("Test Org", "Testing admin perimeter creation");

        // Add admin
        org.addAdmin(admin1);

        // Admin creates a perimeter
        vm.prank(admin1);
        address perimeter = org.createPerimeter("Admin Created Perimeter");

        // Verify the perimeter was created
        address[] memory perimetersList = org.getPerimeters();
        Assert.equal(perimetersList.length, 1, "Organisation should have 1 perimeter");
        Assert.equal(perimetersList[0], perimeter, "Perimeter should match");
    }

    function testMemberCannotCreatePerimeter() public {
        ZTNAOrganisation org = createOrg("Test Org", "Testing member perimeter creation");

        // Add member
        org.addMember(member1);

        // Member tries to create perimeter - should fail
        vm.prank(member1);
        vm.expectRevert();
        org.createPerimeter("Member Perimeter");
    }

    // ======== Use Case 5: Admins can add themselves as perimeter admins ========

    function testOwnerCanAddSelfAsPerimeterAdmin() public {
        ZTNAOrganisation org = createOrg("Test Org", "Testing self-admin");

        // Create a perimeter in the org
        address perimeter = org.createPerimeter("Test Perimeter");

        // Owner adds themselves as perimeter admin
        org.addSelfAsPerimeterAdmin(perimeter, "OrgOwner");

        // Verify the owner is now an admin in the perimeter
        ZTNAPerimeterContract perimeterContract = ZTNAPerimeterContract(perimeter);
        Assert.equal(perimeterContract.isUserAdmin(testOwner), true, "Owner should be perimeter admin");
    }

    function testAdminCanAddSelfAsPerimeterAdmin() public {
        ZTNAOrganisation org = createOrg("Test Org", "Testing admin self-admin");

        // Add org admin
        org.addAdmin(admin1);

        // Create a perimeter in the org
        address perimeter = org.createPerimeter("Test Perimeter");

        // Admin adds themselves as perimeter admin
        vm.prank(admin1);
        org.addSelfAsPerimeterAdmin(perimeter, "OrgAdmin");

        // Verify the admin is now an admin in the perimeter (call from admin1's context)
        ZTNAPerimeterContract perimeterContract = ZTNAPerimeterContract(perimeter);
        vm.prank(admin1);
        Assert.equal(perimeterContract.isUserAdmin(admin1), true, "Admin should be perimeter admin");
    }

    function testMemberCannotAddSelfAsPerimeterAdmin() public {
        ZTNAOrganisation org = createOrg("Test Org", "Testing member self-admin");

        // Add member
        org.addMember(member1);

        // Create a perimeter in the org
        address perimeter = org.createPerimeter("Test Perimeter");

        // Member tries to add themselves as perimeter admin - should fail
        vm.prank(member1);
        vm.expectRevert();
        org.addSelfAsPerimeterAdmin(perimeter, "MemberAdmin");
    }

    function testCannotAddSelfToPerimeterNotInOrg() public {
        ZTNAOrganisation org = createOrg("Test Org", "Testing perimeter org check");

        // Create a perimeter NOT in the org (directly via registry)
        registry.CreateFleet("External Fleet");
        uint256 fleetCount = registry.GetOwnFleetCount();
        ZTNAPerimeterRegistry.FleetMetadataView memory fleet = registry.GetOwnFleet(fleetCount - 1);
        address externalPerimeter = fleet.fleet;

        // Try to add self as admin to external perimeter - should fail
        vm.expectRevert();
        org.addSelfAsPerimeterAdmin(externalPerimeter, "ShouldFail");
    }

    // ======== Use Case 6: Backwards Compatibility ========

    function testExistingPerimetersWorkWithoutOrg() public {
        // Create a perimeter directly via registry (old flow)
        registry.CreateFleet("Legacy Fleet");
        uint256 fleetCount = registry.GetOwnFleetCount();
        ZTNAPerimeterRegistry.FleetMetadataView memory fleet = registry.GetOwnFleet(fleetCount - 1);
        address perimeter = fleet.fleet;

        // Verify the perimeter works as expected
        ZTNAPerimeterContract perimeterContract = ZTNAPerimeterContract(perimeter);
        Assert.equal(perimeterContract.Operator(), address(this), "We should own the perimeter");

        // We can still manage it directly
        perimeterContract.createUser(member1, "Test User", "test@test.com", "avatar.png");
        (, string memory nickname,,,,,) = perimeterContract.getUser(member1);
        Assert.equal(nickname, "Test User", "User should be created in legacy perimeter");
    }

    function testRegistryVersionUpdated() public view {
        Assert.equal(registry.Version(), 118, "Registry version should be 118");
    }

    function testOrganisationContractVersion() public {
        ZTNAOrganisation org = createOrg("Test", "");
        Assert.equal(org.Version(), 202, "Organisation version should be 202");
    }

    // ======== View Functions Tests ========

    function testUpdateOrganisation() public {
        ZTNAOrganisation org = createOrg("Original Name", "Original Desc");

        org.updateOrganisation("Updated Name", "Updated Desc");

        Assert.equal(org.name(), "Updated Name", "Name should be updated");
        Assert.equal(org.description(), "Updated Desc", "Description should be updated");
    }

    function testOnlyOwnerCanUpdateOrganisation() public {
        ZTNAOrganisation org = createOrg("Test Org", "Test");

        vm.prank(nonMember);
        vm.expectRevert();
        org.updateOrganisation("Hacked", "Hacked");
    }

    // ======== Error Cases ========

    function testCannotAddDuplicateAdmin() public {
        ZTNAOrganisation org = createOrg("Test Org", "Test");

        org.addAdmin(admin1);

        vm.expectRevert();
        org.addAdmin(admin1);
    }

    function testCannotAddDuplicateMember() public {
        ZTNAOrganisation org = createOrg("Test Org", "Test");

        org.addMember(member1);

        vm.expectRevert();
        org.addMember(member1);
    }

    function testCannotRemoveNonAdmin() public {
        ZTNAOrganisation org = createOrg("Test Org", "Test");

        vm.expectRevert();
        org.removeAdmin(admin1);
    }

    function testCannotRemoveNonMember() public {
        ZTNAOrganisation org = createOrg("Test Org", "Test");

        vm.expectRevert();
        org.removeMember(member1);
    }

    function testCannotTransferToZeroAddress() public {
        ZTNAOrganisation org = createOrg("Test Org", "Test");

        vm.expectRevert();
        org.transferOwnership(address(0));
    }

    function testCannotRegisterPerimeterAlreadyInOrg() public {
        ZTNAOrganisation org = createOrg("Test Org", "Test");

        // Create and register a perimeter
        address perimeter = org.createPerimeter("Test Perimeter");

        // Try to register again - should fail
        vm.expectRevert();
        org.registerPerimeter(perimeter);
    }

    // ======== Integration Tests ========

    function testFullWorkflow() public {
        // 1. Create an organisation via registry
        ZTNAOrganisation org = createOrg("Acme Corp", "Main organisation");

        // 2. Add admins and members (admins are also members in the new model)
        org.addAdmin(admin1);
        org.addAdmin(admin2);
        org.addMember(member1);
        org.addMember(member2);

        // 3. Admin creates a perimeter
        vm.prank(admin1);
        address perimeter1 = org.createPerimeter("Production");

        // 4. Owner creates another perimeter
        address perimeter2 = org.createPerimeter("Development");

        // 5. Admin adds themselves to perimeter
        vm.prank(admin2);
        org.addSelfAsPerimeterAdmin(perimeter1, "Admin2");

        // 6. Verify state
        address[] memory perimetersList = org.getPerimeters();
        Assert.equal(perimetersList.length, 2, "Should have 2 perimeters");

        address[] memory adminsList = org.getAdmins();
        Assert.equal(adminsList.length, 2, "Should have 2 admins");

        // Members includes both admins and regular members in new model
        address[] memory membersList = org.getMembers();
        Assert.equal(membersList.length, 4, "Should have 4 members (2 admins + 2 regular)");

        // 7. Verify admin2 is admin in perimeter1 (call from admin2's context)
        ZTNAPerimeterContract p1 = ZTNAPerimeterContract(perimeter1);
        vm.prank(admin2);
        Assert.equal(p1.isUserAdmin(admin2), true, "Admin2 should be perimeter admin");

        // Suppress unused variable warning
        perimeter2;
    }

    function testMigrateExistingPerimeterToOrg() public {
        // Simulate existing deployment: create perimeter without org
        registry.CreateFleet("Legacy Production");
        uint256 fleetCount = registry.GetOwnFleetCount();
        ZTNAPerimeterRegistry.FleetMetadataView memory fleet = registry.GetOwnFleet(fleetCount - 1);
        address legacyPerimeter = fleet.fleet;

        // Verify we own it
        ZTNAPerimeterContract perimeterContract = ZTNAPerimeterContract(legacyPerimeter);
        Assert.equal(perimeterContract.Operator(), address(this), "We should own legacy perimeter");

        // Now create an org and migrate
        ZTNAOrganisation org = createOrg("Migrated Org", "Migrating legacy perimeters");

        // Two-step transfer process:
        // Step 1: Transfer the legacy perimeter to the org contract
        perimeterContract.transferOperator(payable(address(org)));
        Assert.equal(perimeterContract.Operator(), address(org), "Org should now own perimeter");

        // Step 2: Register the perimeter with the org
        org.registerPerimeter(legacyPerimeter);
        Assert.equal(org.hasPerimeter(legacyPerimeter), true, "Perimeter should be in org");

        // Add ourselves as admin in the perimeter through the org
        org.addSelfAsPerimeterAdmin(legacyPerimeter, "MigratedOwner");

        // Verify we are now admin (call from our context since we're now a member)
        Assert.equal(perimeterContract.isUserAdmin(address(this)), true, "We should be perimeter admin");
    }

    // ======== Organisation Isolation Tests ========

    function testOrganisationsAreIsolated() public {
        // Create two separate organisations
        ZTNAOrganisation org1 = createOrg("Org 1", "First org");
        ZTNAOrganisation org2 = createOrg("Org 2", "Second org");

        // Add different admins to each
        org1.addAdmin(admin1);
        org2.addAdmin(admin2);

        // Verify isolation
        Assert.equal(org1.isAdmin(admin1), true, "Admin1 should be admin of org1");
        Assert.equal(org1.isAdmin(admin2), false, "Admin2 should not be admin of org1");
        Assert.equal(org2.isAdmin(admin1), false, "Admin1 should not be admin of org2");
        Assert.equal(org2.isAdmin(admin2), true, "Admin2 should be admin of org2");
    }

    function testPerimetersAreIsolatedBetweenOrgs() public {
        ZTNAOrganisation org1 = createOrg("Org 1", "First org");
        ZTNAOrganisation org2 = createOrg("Org 2", "Second org");

        // Create perimeter in org1
        address perimeter1 = org1.createPerimeter("Org1 Perimeter");

        // Create perimeter in org2
        address perimeter2 = org2.createPerimeter("Org2 Perimeter");

        // Verify isolation
        Assert.equal(org1.hasPerimeter(perimeter1), true, "Org1 should have perimeter1");
        Assert.equal(org1.hasPerimeter(perimeter2), false, "Org1 should not have perimeter2");
        Assert.equal(org2.hasPerimeter(perimeter1), false, "Org2 should not have perimeter1");
        Assert.equal(org2.hasPerimeter(perimeter2), true, "Org2 should have perimeter2");
    }

    function testRegistryReturnsAddress() public view {
        address orgImpl = registry.OrganisationContract();
        Assert.notEqual(orgImpl, address(0), "Organisation implementation should not be zero");
    }

    // ======== Registry Membership Tracking Tests ========

    function testAdminMembershipTrackedInRegistry() public {
        ZTNAOrganisation org = createOrg("Test Org", "Testing membership tracking");

        // Add admin
        org.addAdmin(admin1);

        // Check registry tracks the membership
        vm.prank(admin1);
        address[] memory adminOrgs = registry.GetOrganisationsWhereAdmin();

        Assert.equal(adminOrgs.length, 1, "Admin1 should be admin of 1 org");
        Assert.equal(adminOrgs[0], address(org), "Admin org should match");
    }

    function testMemberMembershipTrackedInRegistry() public {
        ZTNAOrganisation org = createOrg("Test Org", "Testing membership tracking");

        // Add member
        org.addMember(member1);

        // Check registry tracks the membership
        vm.prank(member1);
        address[] memory memberOrgs = registry.GetOrganisationsWhereMember();

        Assert.equal(memberOrgs.length, 1, "Member1 should be member of 1 org");
        Assert.equal(memberOrgs[0], address(org), "Member org should match");
    }

    function testRemoveAdminUpdatesRegistry() public {
        ZTNAOrganisation org = createOrg("Test Org", "Testing membership removal");

        // Add then remove admin
        org.addAdmin(admin1);
        org.removeAdmin(admin1);

        // Check registry no longer tracks the membership
        vm.prank(admin1);
        address[] memory adminOrgs = registry.GetOrganisationsWhereAdmin();

        Assert.equal(adminOrgs.length, 0, "Admin1 should be admin of 0 orgs after removal");
    }

    function testRemoveMemberUpdatesRegistry() public {
        ZTNAOrganisation org = createOrg("Test Org", "Testing membership removal");

        // Add then remove member
        org.addMember(member1);
        org.removeMember(member1);

        // Check registry no longer tracks the membership
        vm.prank(member1);
        address[] memory memberOrgs = registry.GetOrganisationsWhereMember();

        Assert.equal(memberOrgs.length, 0, "Member1 should be member of 0 orgs after removal");
    }

    function testTransferOwnershipUpdatesRegistry() public {
        ZTNAOrganisation org = createOrg("Test Org", "Testing ownership transfer tracking");

        // Verify initial ownership tracked
        uint256 ownerOrgCount = registry.GetOwnOrganisationCount();
        Assert.equal(ownerOrgCount, 1, "Owner should have 1 org initially");

        // Transfer ownership
        org.transferOwnership(admin1);

        // Check registry updated for previous owner
        uint256 prevOwnerOrgCount = registry.GetOwnOrganisationCount();
        Assert.equal(prevOwnerOrgCount, 0, "Previous owner should have 0 orgs");

        // Check registry updated for new owner
        vm.prank(admin1);
        uint256 newOwnerOrgCount = registry.GetOwnOrganisationCount();
        Assert.equal(newOwnerOrgCount, 1, "New owner should have 1 org");
    }

    function testGetAllMyOrganisations() public {
        // Create org owned by testOwner
        ZTNAOrganisation org1 = createOrg("Org 1", "First");

        // Create org owned by admin1
        vm.prank(admin1);
        address org2Addr = registry.CreateOrganisation("Org 2", "Second");
        ZTNAOrganisation org2 = ZTNAOrganisation(org2Addr);

        // Add testOwner as admin to org2 (in new model, admins are also members)
        vm.prank(admin1);
        org2.addAdmin(testOwner);

        // Create org owned by admin2
        vm.prank(admin2);
        address org3Addr = registry.CreateOrganisation("Org 3", "Third");
        ZTNAOrganisation org3 = ZTNAOrganisation(org3Addr);

        // Add testOwner as member to org3
        vm.prank(admin2);
        org3.addMember(testOwner);

        // Get all organisations for testOwner
        (address[] memory ownedOrgs, address[] memory adminOrgs, address[] memory memberOrgs) =
            registry.GetAllMyOrganisations();

        Assert.equal(ownedOrgs.length, 1, "Should own 1 org");
        Assert.equal(ownedOrgs[0], address(org1), "Should own org1");

        Assert.equal(adminOrgs.length, 1, "Should be admin of 1 org");
        Assert.equal(adminOrgs[0], org2Addr, "Should be admin of org2");

        // In new model, admins are also members, so memberOrgs includes org2 and org3
        Assert.equal(memberOrgs.length, 2, "Should be member of 2 orgs (admin+member)");
    }

    function testUserAcrossMultipleOrganisations() public {
        // Create multiple orgs
        ZTNAOrganisation org1 = createOrg("Org 1", "First");
        ZTNAOrganisation org2 = createOrg("Org 2", "Second");
        ZTNAOrganisation org3 = createOrg("Org 3", "Third");

        // Add admin1 to all orgs as admin
        org1.addAdmin(admin1);
        org2.addAdmin(admin1);
        org3.addAdmin(admin1);

        // Check admin1 sees all orgs
        vm.prank(admin1);
        address[] memory adminOrgs = registry.GetOrganisationsWhereAdmin();

        Assert.equal(adminOrgs.length, 3, "Admin1 should be admin of 3 orgs");
    }

    // ======== Edge Case Tests ========

    function testOwnerAddingSelfAsAdmin() public {
        ZTNAOrganisation org = createOrg("Test Org", "Edge case test");

        // Owner tries to add themselves as admin (they're already owner)
        org.addAdmin(testOwner);

        // Should be tracked as admin
        Assert.equal(org.isAdmin(testOwner), true, "Owner should also be admin");

        // Check registry tracks this
        address[] memory adminOrgs = registry.GetOrganisationsWhereAdmin();
        Assert.equal(adminOrgs.length, 1, "Owner should be tracked as admin of 1 org");
    }

    function testOwnerAddingSelfAsMember() public {
        ZTNAOrganisation org = createOrg("Test Org", "Edge case test");

        // Owner adds themselves as member
        org.addMember(testOwner);

        // Should be tracked as member
        Assert.equal(org.isMember(testOwner), true, "Owner should also be member");

        // Check registry tracks this
        address[] memory memberOrgs = registry.GetOrganisationsWhereMember();
        Assert.equal(memberOrgs.length, 1, "Owner should be tracked as member of 1 org");
    }

    function testAddAsMemberThenPromoteToAdmin() public {
        ZTNAOrganisation org = createOrg("Test Org", "Edge case test");

        // Add user1 as member first
        org.addMember(admin1);

        // Promote to admin using setAdmin
        org.setAdmin(admin1, true);

        // Verify both roles (admin is a member with admin flag)
        Assert.equal(org.isMember(admin1), true, "User should be member");
        Assert.equal(org.isAdmin(admin1), true, "User should be admin");

        // Check registry tracks both
        vm.startPrank(admin1);
        address[] memory memberOrgs = registry.GetOrganisationsWhereMember();
        address[] memory adminOrgs = registry.GetOrganisationsWhereAdmin();
        vm.stopPrank();

        Assert.equal(memberOrgs.length, 1, "User should be tracked as member of 1 org");
        Assert.equal(adminOrgs.length, 1, "User should be tracked as admin of 1 org");
    }

    function testRemoveAdminKeepsMemberRole() public {
        ZTNAOrganisation org = createOrg("Test Org", "Edge case test");

        // Add user as admin (which also makes them a member)
        org.addAdmin(admin1);

        // Verify they are both admin and member
        Assert.equal(org.isMember(admin1), true, "User should be member");
        Assert.equal(org.isAdmin(admin1), true, "User should be admin");

        // Remove admin role (but keep as member)
        org.removeAdmin(admin1);

        // Should still be member but not admin
        Assert.equal(org.isMember(admin1), true, "User should still be member");
        Assert.equal(org.isAdmin(admin1), false, "User should not be admin");

        // Check registry reflects this
        vm.startPrank(admin1);
        address[] memory memberOrgs = registry.GetOrganisationsWhereMember();
        address[] memory adminOrgs = registry.GetOrganisationsWhereAdmin();
        vm.stopPrank();

        Assert.equal(memberOrgs.length, 1, "User should still be tracked as member");
        Assert.equal(adminOrgs.length, 0, "User should not be tracked as admin");
    }

    function testRemoveMemberRemovesAdminToo() public {
        ZTNAOrganisation org = createOrg("Test Org", "Edge case test");

        // Add user as admin (which also makes them a member)
        org.addAdmin(admin1);

        // Remove member - should also remove admin status
        org.removeMember(admin1);

        // Should be neither member nor admin
        Assert.equal(org.isMember(admin1), false, "User should not be member");
        Assert.equal(org.isAdmin(admin1), false, "User should not be admin");

        // Check registry reflects this
        vm.startPrank(admin1);
        address[] memory memberOrgs = registry.GetOrganisationsWhereMember();
        address[] memory adminOrgs = registry.GetOrganisationsWhereAdmin();
        vm.stopPrank();

        Assert.equal(memberOrgs.length, 0, "User should not be tracked as member");
        Assert.equal(adminOrgs.length, 0, "User should not be tracked as admin");
    }

    function testAddRemoveAddAdmin() public {
        ZTNAOrganisation org = createOrg("Test Org", "Edge case test");

        // Add admin
        org.addAdmin(admin1);
        vm.prank(admin1);
        Assert.equal(registry.GetOrganisationsWhereAdmin().length, 1, "Should be admin of 1");

        // Remove member (which also removes admin)
        org.removeMember(admin1);
        vm.prank(admin1);
        Assert.equal(registry.GetOrganisationsWhereAdmin().length, 0, "Should be admin of 0");

        // Add again
        org.addAdmin(admin1);
        vm.prank(admin1);
        Assert.equal(registry.GetOrganisationsWhereAdmin().length, 1, "Should be admin of 1 again");
    }

    function testMembershipAcrossMultipleOrgsWithAddRemove() public {
        ZTNAOrganisation org1 = createOrg("Org 1", "First");
        ZTNAOrganisation org2 = createOrg("Org 2", "Second");

        // Add admin1 to both
        org1.addAdmin(admin1);
        org2.addAdmin(admin1);

        vm.prank(admin1);
        Assert.equal(registry.GetOrganisationsWhereAdmin().length, 2, "Should be admin of 2 orgs");

        // Remove from one
        org1.removeAdmin(admin1);

        vm.prank(admin1);
        address[] memory adminOrgs = registry.GetOrganisationsWhereAdmin();
        Assert.equal(adminOrgs.length, 1, "Should be admin of 1 org");
        Assert.equal(adminOrgs[0], address(org2), "Should still be admin of org2");
    }

    function testRegistryVersionUpdatedWithMembership() public view {
        Assert.equal(registry.Version(), 118, "Registry version should be 118");
    }

    function testOrganisationVersionUpdatedWithMembership() public {
        ZTNAOrganisation org = createOrg("Test", "");
        Assert.equal(org.Version(), 202, "Organisation version should be 202");
    }

    // ======== Member Info Field Tests ========

    function testAddMemberWithInfo() public {
        ZTNAOrganisation org = createOrg("Test Org", "Testing member info");

        // Add member with all info fields
        org.addMember(member1, "Alice", "alice@example.com", "https://example.com/alice.png", false);

        // Verify member info
        ZTNAOrganisation.MemberView memory info = org.getMember(member1);
        Assert.equal(info.user, member1, "User address should match");
        Assert.equal(info.nickname, "Alice", "Nickname should match");
        Assert.equal(info.email, "alice@example.com", "Email should match");
        Assert.equal(info.avatarURI, "https://example.com/alice.png", "Avatar URI should match");
        Assert.equal(info.isAdmin, false, "Should not be admin");
    }

    function testAddAdminWithInfo() public {
        ZTNAOrganisation org = createOrg("Test Org", "Testing admin info");

        // Add admin with all info fields
        org.addMember(admin1, "Bob Admin", "bob@example.com", "https://example.com/bob.png", true);

        // Verify member info
        ZTNAOrganisation.MemberView memory info = org.getMember(admin1);
        Assert.equal(info.user, admin1, "User address should match");
        Assert.equal(info.nickname, "Bob Admin", "Nickname should match");
        Assert.equal(info.email, "bob@example.com", "Email should match");
        Assert.equal(info.avatarURI, "https://example.com/bob.png", "Avatar URI should match");
        Assert.equal(info.isAdmin, true, "Should be admin");
    }

    function testUpdateMemberInfo() public {
        ZTNAOrganisation org = createOrg("Test Org", "Testing member update");

        // Add member
        org.addMember(member1, "Alice", "alice@old.com", "", false);

        // Update member info
        org.updateMember(member1, "Alice Updated", "alice@new.com", "https://new.com/alice.png");

        // Verify updated info
        ZTNAOrganisation.MemberView memory info = org.getMember(member1);
        Assert.equal(info.nickname, "Alice Updated", "Nickname should be updated");
        Assert.equal(info.email, "alice@new.com", "Email should be updated");
        Assert.equal(info.avatarURI, "https://new.com/alice.png", "Avatar should be updated");
    }

    function testGetMembersDetailed() public {
        ZTNAOrganisation org = createOrg("Test Org", "Testing detailed members");

        // Add members with info
        org.addMember(member1, "Member 1", "m1@example.com", "", false);
        org.addMember(admin1, "Admin 1", "a1@example.com", "", true);

        // Get detailed members
        ZTNAOrganisation.MemberView[] memory allMembers = org.getMembersDetailed();

        Assert.equal(allMembers.length, 2, "Should have 2 members");

        // Verify one of them is admin
        bool foundAdmin = false;
        bool foundMember = false;
        for (uint256 i = 0; i < allMembers.length; i++) {
            if (allMembers[i].user == admin1) {
                Assert.equal(allMembers[i].isAdmin, true, "Admin1 should be admin");
                Assert.equal(allMembers[i].nickname, "Admin 1", "Admin nickname should match");
                foundAdmin = true;
            }
            if (allMembers[i].user == member1) {
                Assert.equal(allMembers[i].isAdmin, false, "Member1 should not be admin");
                Assert.equal(allMembers[i].nickname, "Member 1", "Member nickname should match");
                foundMember = true;
            }
        }
        Assert.equal(foundAdmin, true, "Should have found admin");
        Assert.equal(foundMember, true, "Should have found member");
    }

    // ======== View Function Access Control Tests ========

    function testNonMemberCannotViewMembers() public {
        ZTNAOrganisation org = createOrg("Test Org", "Testing access control");
        org.addMember(member1);

        // Non-member should not be able to view members
        vm.prank(nonMember);
        vm.expectRevert();
        org.getMembers();
    }

    function testNonMemberCannotViewAdmins() public {
        ZTNAOrganisation org = createOrg("Test Org", "Testing access control");
        org.addAdmin(admin1);

        // Non-member should not be able to view admins
        vm.prank(nonMember);
        vm.expectRevert();
        org.getAdmins();
    }

    function testNonMemberCannotViewPerimeters() public {
        ZTNAOrganisation org = createOrg("Test Org", "Testing access control");
        org.createPerimeter("Test Perimeter");

        // Non-member should not be able to view perimeters
        vm.prank(nonMember);
        vm.expectRevert();
        org.getPerimeters();
    }

    function testNonMemberCannotViewMemberDetails() public {
        ZTNAOrganisation org = createOrg("Test Org", "Testing access control");
        org.addMember(member1);

        // Non-member should not be able to view member details
        vm.prank(nonMember);
        vm.expectRevert();
        org.getMember(member1);
    }

    function testMemberCanViewOrganisationData() public {
        ZTNAOrganisation org = createOrg("Test Org", "Testing member access");
        org.addMember(member1);
        org.addMember(member2);
        org.addAdmin(admin1);

        // Member should be able to view data
        vm.startPrank(member1);
        address[] memory membersList = org.getMembers();
        Assert.equal(membersList.length, 3, "Should see 3 members");

        address[] memory adminsList = org.getAdmins();
        Assert.equal(adminsList.length, 1, "Should see 1 admin");
        vm.stopPrank();
    }

    function testOwnerCanViewOrganisationData() public {
        ZTNAOrganisation org = createOrg("Test Org", "Testing owner access");
        org.addMember(member1);

        // Owner should be able to view data even without being added as member
        address[] memory membersList = org.getMembers();
        Assert.equal(membersList.length, 1, "Owner should see 1 member");
    }

    function testNonMemberCanCheckMembershipStatus() public {
        ZTNAOrganisation org = createOrg("Test Org", "Testing public functions");
        org.addMember(member1);
        org.addAdmin(admin1);

        // Anyone can check membership status (these are public)
        vm.prank(nonMember);
        Assert.equal(org.isMember(member1), true, "Member check should work");

        vm.prank(nonMember);
        Assert.equal(org.isAdmin(admin1), true, "Admin check should work");

        vm.prank(nonMember);
        Assert.equal(org.isOwner(testOwner), true, "Owner check should work");
    }

    function testSetAdminChangesStatus() public {
        ZTNAOrganisation org = createOrg("Test Org", "Testing setAdmin");

        // Add as regular member
        org.addMember(member1);
        Assert.equal(org.isAdmin(member1), false, "Should not be admin initially");

        // Promote to admin
        org.setAdmin(member1, true);
        Assert.equal(org.isAdmin(member1), true, "Should be admin after setAdmin");

        // Demote from admin
        org.setAdmin(member1, false);
        Assert.equal(org.isAdmin(member1), false, "Should not be admin after demotion");
        Assert.equal(org.isMember(member1), true, "Should still be member");
    }

    function testOnlyOwnerCanSetAdmin() public {
        ZTNAOrganisation org = createOrg("Test Org", "Testing setAdmin access");

        org.addMember(member1);
        org.addAdmin(admin1);

        // Admin should not be able to promote others
        vm.prank(admin1);
        vm.expectRevert();
        org.setAdmin(member1, true);
    }

    function testOnlyOwnerCanAddAdminViaAddMember() public {
        ZTNAOrganisation org = createOrg("Test Org", "Testing addAdmin access");

        org.addAdmin(admin1);

        // Admin should not be able to add other admins directly
        vm.prank(admin1);
        vm.expectRevert();
        org.addMember(member1, "Test", "", "", true);
    }
}

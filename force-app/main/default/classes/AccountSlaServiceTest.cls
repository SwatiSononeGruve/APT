@IsTest
private class AccountSlaServiceTest {
    @IsTest
    static void assignsTierByAnnualRevenue() {
        System.assertEquals('Bronze', AccountSlaService.tierFor(null));
        System.assertEquals('Bronze', AccountSlaService.tierFor(500000));
        System.assertEquals('Silver', AccountSlaService.tierFor(1000000));
        System.assertEquals('Gold', AccountSlaService.tierFor(25000000));
    }
}

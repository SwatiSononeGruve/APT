public with sharing class AccountSlaService {
    public static String tierFor(Decimal annualRevenue) {
        if (annualRevenue == null) return 'Bronze';
        if (annualRevenue >= 10000000) return 'Gold';
        if (annualRevenue >= 1000000) return 'Silver';
        return 'Bronze';
    }
}

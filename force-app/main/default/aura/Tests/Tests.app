<aura:application >

    <c:lts_mochaRunner testFiles="{!join(',', 
        $Resource.donationFormTests,
        $Resource.donationFormDonationTests,
        $Resource.productTilesTests,
        $Resource.paymentRefundTests,
        $Resource.batchOrderCreateTests,
        $Resource.donationCancelTests
    )}" />

</aura:application>
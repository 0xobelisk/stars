module stars::stars {
    use sui::coin::{Self, TreasuryCap};
    use sui::url;


    public struct STARS has drop {}

    fun init(witness: STARS, ctx: &mut TxContext) {
        let (mut treasury_cap, metadata) = coin::create_currency(
            witness,
            7,
            b"STARS",
            b"STARS Token",
            b"Stars point",
            option::some(url::new_unsafe_from_bytes(b"https://raw.githubusercontent.com/0xobelisk/dubhe/main/assets/stars.gif")),
            ctx
        );

        let coin = coin::mint(&mut treasury_cap, 1000000000000 * 10000000u64, ctx);
        transfer::public_transfer(coin, @0xc1cde08091a9a94b39cfbf90f48f276f41bbd05235138ff5634e31931c5a4869);

        transfer::public_freeze_object(metadata);
        transfer::public_transfer(treasury_cap, tx_context::sender(ctx));   
    }

    public entry fun mint(
        treasury_cap: &mut TreasuryCap<STARS>,
        amount: u64,
        ctx: &mut TxContext,
    ) {
        let coin = coin::mint(treasury_cap, amount, ctx);
        transfer::public_transfer(coin, @0xc1cde08091a9a94b39cfbf90f48f276f41bbd05235138ff5634e31931c5a4869);
    }
}
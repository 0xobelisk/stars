module stars::claim;

use sui::table::{Self, Table};
use sui::ed25519;
use sui::balance::{Self, Balance};
use stars::stars::STARS;
use sui::coin::{Self, Coin};

const PUBLIC_KEY: vector<u8> = x"59337460cde859f38e6f7a98cb706d14289984a509ab6da1d08726f193cbc7ed";
const ADMIN: address = @0xffae791c3b063c623f507d1339ba8e15796dc62f0d42765cfaa221c645a34aa4;

public struct ClaimedLedger has key, store {
    id: UID,
    claimed: Table<address, u64>,
    balance: Balance<STARS>,
}

public entry fun initialize(ctx: &mut TxContext) {
      assert!(ctx.sender() == ADMIN, 1);
      let ledger = ClaimedLedger {
            id: object::new(ctx),
            claimed: table::new(ctx),
            balance: balance::zero(),
      };
      transfer::public_share_object(ledger);
}


/// Deposit STARS to the ledger
public entry fun deposit(
    ledger: &mut ClaimedLedger,
    coin: Coin<STARS>,
) {
    let amount = coin::into_balance(coin);
    balance::join(&mut ledger.balance, amount);
}

/// Claim STARS from the ledger
public entry fun claim(
    ledger: &mut ClaimedLedger,
    to: address,
    amount: u64,
    signature: vector<u8>,
    ctx: &mut TxContext,
) {
    assert!(ctx.sender() == to, 1);
    let message = get_message(to, amount);
    let verified = ed25519::ed25519_verify(&signature, &PUBLIC_KEY, &message);
    assert!(verified, 1);
    table::add<address, u64>(&mut ledger.claimed, to, amount);
    let balance = balance::split(&mut ledger.balance, amount);
    let coin = coin::from_balance(balance, ctx);
    sui::transfer::public_transfer(coin, to);
}

public fun get_message(
    to: address,
    amount: u64,
): vector<u8> {
    let mut message = vector::empty();
    message.append(b"{\"address\":\"0x");
    message.append(to.to_string().into_bytes());
    message.append(b"\",\"amount\":\"");
    message.append(amount.to_string().into_bytes());
    message.append(b"\",\"memo\":\"star\"}");
    message
}

public fun is_claimed(ledger: &ClaimedLedger, to: address): bool {
      table::contains(&ledger.claimed, to)
}

#[test_only]
use sui::test_scenario::{Self, Scenario};

#[test]
fun test_deposit() {
      let mut scenario = test_scenario::begin(ADMIN);
      let ctx = scenario.ctx();
      let stars0 = coin::mint_for_testing<STARS>(100, ctx);
      let stars1 = coin::mint_for_testing<STARS>(10000, ctx);
      initialize(ctx);

      scenario.next_tx(ADMIN);
      let mut ledger = test_scenario::take_shared<ClaimedLedger>(&scenario);
      deposit(&mut ledger, stars0);

      deposit(&mut ledger, stars1);
      std::debug::print(&ledger);
      test_scenario::return_shared<ClaimedLedger>(ledger);

      scenario.end();
}


#[test]
public fun test_claim() {
      let message = b"{\"address\":\"0xd88bfb1a3df8c518bd678425ea02a510eb50d5c0d87259d9515ab07cd69ab465\",\"amount\":\"100000\",\"memo\":\"star\"}";
      let address = @0xd88bfb1a3df8c518bd678425ea02a510eb50d5c0d87259d9515ab07cd69ab465;
      let amount = 100000;

      let signature = x"bb558b3181c6d1f0ba21f52f46de39ee102265b46e69ced8a6ca5eb155f0b0533c0d697a85a6fe5b29f027c72b481ffe1b9e32c14dbef7a0a32bc2b7bf30f108";

      // let message_hash = sha2_256(message);
      // std::debug::print(&message_hash);
      let verified = ed25519::ed25519_verify(&signature, &PUBLIC_KEY, &message);
      assert!(verified, 1);


      let mut scenario = test_scenario::begin(ADMIN);
      let ctx = scenario.ctx();
      let stars0 = coin::mint_for_testing<STARS>(1000000, ctx);
      // let stars1 = coin::mint_for_testing<STARS>(100000, ctx);
      initialize(ctx);

      scenario.next_tx(address);
      let mut ledger = test_scenario::take_shared<ClaimedLedger>(&scenario);
      deposit(&mut ledger, stars0);

      let ctx = scenario.ctx();
      assert!(!is_claimed(&ledger, address), 1);
      claim(&mut ledger, address, amount, signature, ctx);
      assert!(is_claimed(&ledger, address), 1);
      std::debug::print(&ledger);

      test_scenario::return_shared<ClaimedLedger>(ledger);
      scenario.end();
}


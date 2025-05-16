#[allow(lint(share_owned))]module stars::stars_genesis {

  use std::ascii::string;

  use sui::clock::Clock;

  use stars::stars_dapp_system;

  public entry fun run(clock: &Clock, ctx: &mut TxContext) {
    // Create schemas
    let mut schema = stars::stars_schema::create(ctx);
    // Setup default storage
    stars_dapp_system::create(&mut schema, string(b"stars"),string(b"stars"), clock , ctx);
    // Logic that needs to be automated once the contract is deployed
    stars::stars_deploy_hook::run(&mut schema, ctx);
    // Authorize schemas and public share objects
    sui::transfer::public_share_object(schema);
  }
}

declare
  foo integer;
begin

  foo := acs_sc_impl.delete_alias(
    'PaymentGateway',
    'authorize-gateway',
    'Authorize'
  );

  foo := acs_sc_impl.delete_alias(
    'PaymentGateway',
    'authorize-gateway',
    'ChargeCard'
  );

  foo := acs_sc_impl.delete_alias(
    'PaymentGateway',
    'authorize-gateway',
    'Return'
  );

  foo := acs_sc_impl.delete_alias(
    'PaymentGateway',
    'authorize-gateway',
    'Void'
  );

  foo := acs_sc_impl.delete_alias(
    'PaymentGateway',
    'authorize-gateway',
    'Info'
  );

  acs_sc_binding.delete(
    contract_name => 'PaymentGateway',
    impl_name => 'authorize-gateway'
  );

  acs_sc_impl.delete(
    'PaymentGateway',
    'authorize-gateway'
  );

end;
/
show errors
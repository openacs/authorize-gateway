-- This is an Authorize.net implementation of the PaymentGateway
-- service contract

declare
  foo integer;
begin
  foo := acs_sc_impl.new(
	   'PaymentGateway',               	-- impl_contract_name
           'authorize-gateway',                 -- impl_name
	   'authorize-gateway'                  -- impl_owner_name
  );

  foo := acs_sc_impl.new_alias(
           'PaymentGateway',			-- impl_contract_name
           'authorize-gateway',			-- impl_name
	   'Authorize', 			-- impl_operation_name
	   'authorize_gateway.authorize', 	-- impl_alias
	   'TCL'    				-- impl_pl
  );

  foo := acs_sc_impl.new_alias(
           'PaymentGateway',			-- impl_contract_name
           'authorize-gateway',			-- impl_name
	   'ChargeCard', 			-- impl_operation_name
	   'authorize_gateway.chargecard', 	-- impl_alias
	   'TCL'    				-- impl_pl
  );

  foo := acs_sc_impl.new_alias(
           'PaymentGateway',			-- impl_contract_name
           'authorize-gateway',			-- impl_name
	   'Return', 				-- impl_operation_name
	   'authorize_gateway.return', 		-- impl_alias
	   'TCL'    				-- impl_pl
  );

  foo := acs_sc_impl.new_alias(
           'PaymentGateway',			-- impl_contract_name
           'authorize-gateway',			-- impl_name
	   'Void', 				-- impl_operation_name
	   'authorize_gateway.void', 		-- impl_alias
	   'TCL'    				-- impl_pl
  );

  foo := acs_sc_impl.new_alias(
           'PaymentGateway',			-- impl_contract_name
           'authorize-gateway',			-- impl_name
	   'Info', 				-- impl_operation_name
	   'authorize_gateway.info', 		-- impl_alias
	   'TCL'    				-- impl_pl
  );

end;
/
show errors

-- Add the binding

declare
        foo integer;
begin

        acs_sc_binding.new (
            contract_name => 'PaymentGateway',
            impl_name => 'authorize-gateway'
        );
end;
/
show errors

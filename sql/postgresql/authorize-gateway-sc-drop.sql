select acs_sc_binding__delete(
    'PaymentGateway',
    'authorize-gateway'
);

select acs_sc_impl_alias__delete(
    'PaymentGateway',
    'authorize-gateway',
    'Authorize'
);

select acs_sc_impl_alias__delete(
    'PaymentGateway',
    'authorize-gateway',
    'ChargeCard'
);

select acs_sc_impl_alias__delete(
    'PaymentGateway',
    'authorize-gateway',
    'Return'
);

select acs_sc_impl_alias__delete(
    'PaymentGateway',
    'authorize-gateway',
    'Void'
);

select acs_sc_impl_alias__delete(
    'PaymentGateway',
    'authorize-gateway',
    'Info'
);

select acs_sc_binding__delete(
    'PaymentGateway',
    'authorize-gateway'
);

select acs_sc_impl__delete(
    'PaymentGateway',
    'authorize-gateway'
);


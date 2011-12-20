class Admin::TransactionsController < Admin::PublicationSubclassesController
  defaults :resource_class => TransactionEdition
end

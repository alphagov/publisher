class Admin::LocalTransactionsController < Admin::PublicationSubclassesController
  defaults :resource_class => LocalTransactionEdition
end

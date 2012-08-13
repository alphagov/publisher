# encoding: utf-8

module Mail
  class IMAP < Retriever
    # Monkey patching this method to get us the changes included in
    # https://github.com/mikel/mail/commit/219717c453d1b275ab6235cb1909e49eaabba409
    # but not rolled out as a 2.4.5 or 2.5.0 gem yet
    def find(options={}, &block)
      options = validate_options(options)

      start do |imap|
        options[:read_only] ? imap.examine(options[:mailbox]) : imap.select(options[:mailbox])

        message_ids = imap.uid_search(options[:keys])
        message_ids.reverse! if options[:what].to_sym == :last
        message_ids = message_ids.first(options[:count]) if options[:count].is_a?(Integer)
        message_ids.reverse! if (options[:what].to_sym == :last && options[:order].to_sym == :asc) ||
                                (options[:what].to_sym != :last && options[:order].to_sym == :desc)

        if block_given?
          message_ids.each do |message_id|
            fetchdata = imap.uid_fetch(message_id, ['RFC822'])[0]
            new_message = Mail.new(fetchdata.attr['RFC822'])
            new_message.mark_for_delete = true if options[:delete_after_find]
            if block.arity == 3
              yield new_message, imap, message_id
            else
              yield new_message
            end
            imap.uid_store(message_id, "+FLAGS", [Net::IMAP::DELETED]) if options[:delete_after_find] && new_message.is_marked_for_delete?
          end
          imap.expunge if options[:delete_after_find]
        else
          emails = []
          message_ids.each do |message_id|
            fetchdata = imap.uid_fetch(message_id, ['RFC822'])[0]
            emails << Mail.new(fetchdata.attr['RFC822'])
            imap.uid_store(message_id, "+FLAGS", [Net::IMAP::DELETED]) if options[:delete_after_find]
          end
          imap.expunge if options[:delete_after_find]
          emails.size == 1 && options[:count] == 1 ? emails.first : emails
        end
      end
    end
  end
end

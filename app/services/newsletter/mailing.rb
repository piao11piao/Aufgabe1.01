module Newsletter
  class Mailing

    attr_reader :subscription, :new_categories
    attr_accessor :from

    def self.cronjob
      MailSubscription.confirmed.each do |s|
        ms = new(s)
        if ms.sendable?
          ms.send!
        end
      end
    end

    def initialize(subscription, from: subscription.interval_from.ago)
      @subscription = subscription
      @from = from
    end

    def sendable?
      sections.any? && subscription.due?
    end

    def salutation
      @subscription.salutation
    end

    def intro
      Setting.mail_intro.gsub(/\{\{([^\}]+)\}\}/) do |pattern|
        case $1.strip
        when 'top' then count.to_s
        when 'total_count' then total_count.to_s
        when 'categories' then categories.map(&:name).to_sentence
        else "missing_token #{pattern}"
        end
      end
    end

    def send!
      mail.deliver_now!
    rescue StandardError => e
      puts "[NewsletterMailing] #{e.inspect}"
    ensure
      subscription.update_column :last_send_date, Date.today
    end

    def mail
      NewsletterMailer.newsletter(self)
    end

    def email
      @subscription.email
    end

    def sections
      @sections ||=
        begin
          s = []
          categories.each do |cat|
            s << CategorySection.new(cat, self)
          end

          all_news_items = s.flat_map(&:news_items).sort_by{|i| -(i.absolute_score || 0)}
          @total_count = all_news_items.count
          filtered_news_items = all_news_items.take(@subscription.limit || 100)
          s.each do |section|
            section.news_items = section.news_items.select{|ni| filtered_news_items.include?(ni) }
          end

          # uniq filtern
          already_checked = []
          s.sort_by{|i| i.news_items.count }.each do |section|
            section.news_items = section.news_items - already_checked
            already_checked += section.news_items
          end
          s.reject!{|i| i.news_items.count == 0 }
          @new_categories = Category.where('created_at between ? and ?', *interval) - categories
          if @subscription.extended_member?
            section = ExtendedMemberSection.new(self)
            if section.news_items.any?
              s.prepend
            end
          end
          s
        end
      # Alle News-Items bilden
    end

    def categories
      @categories ||= begin
                        category_ids = @subscription.categories.reject(&:blank?)
                        base = Category.where(id: category_ids).to_a
                        if has_uncatorized?
                          base + [Uncategorized.new]
                        else
                          base
                        end
                      end
    end

    def count
      sections.map{|i| i.respond_to?(:news_items) ? i.news_items.count : 0}.sum
    end

    def total_count
      @total_count
    end

    def has_uncatorized?
      @subscription.categories.include? 0
    end

    def interval
      to = from + subscription.interval_from
      [ from, to ]
    end

    private

  end
end

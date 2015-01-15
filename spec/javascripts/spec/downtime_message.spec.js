describe('A downtime message module', function() {
  "use strict";

  var downtimeMessage,
      form;

  beforeEach(function() {

    var formHTML = '<select>\
      <option value="00">00</option>\
      <option value="01">01</option>\
      <option value="02">02</option>\
      <option value="03">03</option>\
      <option value="04">04</option>\
      <option value="05">05</option>\
      <option value="06">06</option>\
      <option value="07">07</option>\
      <option value="08">08</option>\
      <option value="09">09</option>\
      <option value="10">10</option>\
      <option value="11">11</option>\
      <option value="12">12</option>\
      <option value="13">13</option>\
      <option value="14">14</option>\
      <option value="15">15</option>\
      <option value="16">16</option>\
      <option value="17">17</option>\
      <option value="18">18</option>\
      <option value="19">19</option>\
      <option value="20">20</option>\
      <option value="21">21</option>\
      <option value="22">22</option>\
      <option value="23">23</option>\
    </select>\
    <select>\
      <option value="00">00</option>\
      <option value="15">15</option>\
      <option value="30">30</option>\
      <option value="45">45</option>\
    </select>\
    <select>\
      <option value="1">1</option>\
      <option value="2">2</option>\
      <option value="3">3</option>\
      <option value="4">4</option>\
      <option value="5">5</option>\
      <option value="6">6</option>\
      <option value="7">7</option>\
      <option value="8">8</option>\
      <option value="9">9</option>\
      <option value="10">10</option>\
      <option value="11">11</option>\
      <option value="12">12</option>\
      <option value="13">13</option>\
      <option value="14">14</option>\
      <option value="15">15</option>\
      <option value="16">16</option>\
      <option value="17">17</option>\
      <option value="18">18</option>\
      <option value="19">19</option>\
      <option value="20">20</option>\
      <option value="21">21</option>\
      <option value="22">22</option>\
      <option value="23">23</option>\
      <option value="24">24</option>\
      <option value="25">25</option>\
      <option value="26">26</option>\
      <option value="27">27</option>\
      <option value="28">28</option>\
      <option value="29">29</option>\
      <option value="30">30</option>\
      <option value="31">31</option>\
    </select>\
    <select>\
      <option value="1">January</option>\
      <option value="2">February</option>\
      <option value="3">March</option>\
      <option value="4">April</option>\
      <option value="5">May</option>\
      <option value="6">June</option>\
      <option value="7">July</option>\
      <option value="8">August</option>\
      <option value="9">September</option>\
      <option value="10">October</option>\
      <option value="11">November</option>\
      <option value="12">December</option>\
    </select>\
    <select>\
      <option value="2015"></option>\
      <option value="2016"></option>\
    </select>';

    form = $('\
      <form>\
        <div class="js-start-time">'+ formHTML +'</div>\
        <div class="js-stop-time">'+ formHTML +'</div>\
        <textarea class="js-downtime-message">starting message</textarea>\
        <div class="js-schedule-message">starting message</div>\
        <input type="submit" class="js-submit">\
      </form>'
    );

    $('body').append(form);

    downtimeMessage = new GOVUKAdmin.Modules.DowntimeMessage();
    downtimeMessage.start(form);
  });

  afterEach(function() {
    form.remove();
  });

  describe('when starting', function() {
    it('leaves any existing downtime message alone' , function() {
      expectDowntimeMessageToMatch('starting message');
    });

    it('disables the form if the preloaded dates aren’t valid' , function() {
      expectDisabledForm();
    });
  });

  describe('when selecting dates', function() {
    it('generates a downtime message and a schedule message' , function() {
      selectStartDate();
      selectStopDate({hour: '02'});
      expectDowntimeMessageToMatch('This service will be unavailable from 1am to 2am on Thursday 1 January.');
      expectScheduleMessageToMatch('A downtime message will show from 1am on Wednesday 31 December');

      selectStopDate({hour: '03'});
      expectDowntimeMessageToMatch('from 1am to 3am on Thursday 1 January.');
      expectScheduleMessageToMatch('from 1am on Wednesday 31 December');

      expectEnabledForm();
    });

    describe('that are the same', function() {
      beforeEach(function() {
        selectStartDate();
        selectStopDate();
      });

      it('doesn’t generate a message', function() {
        expectDowntimeMessageToBe('');
      });

      it('disables the form', function() {
        expectDisabledForm();
      });
    });

    describe('with a stop date before the start date', function() {
      beforeEach(function() {
        selectStartDate({hour: '03'});
        selectStopDate({hour: '01'});
      });

      it('doesn’t generate a message', function() {
        expectDowntimeMessageToBe('');
      });

      it('disables the form', function() {
        expectDisabledForm();
      });
    });

    describe('the generated messages', function() {
      it('use a 12 hour clock' , function() {
        selectStartDate({hour: '11'});
        selectStopDate({hour: '15'});
        expectDowntimeMessageToMatch('from 11am to 3pm on Thursday 1 January.');
        expectScheduleMessageToMatch('from 11am on Wednesday 31 December');
        expectEnabledForm();
      });

      it('use midnight instead of 12am' , function() {
        selectStartDate({hour: '00'});
        selectStopDate({hour: '02'});
        expectDowntimeMessageToMatch('from midnight to 2am on Thursday 1 January.');
        expectScheduleMessageToMatch('from midnight on Wednesday 31 December');
      });

      it('use midday instead of 12pm' , function() {
        selectStartDate({hour: '12'});
        selectStopDate({hour: '14'});
        expectDowntimeMessageToMatch('from midday to 2pm on Thursday 1 January.');
        expectScheduleMessageToMatch('from midday on Wednesday 31 December');
      });

      it('includes minutes when they are not 0' , function() {
        selectStartDate({hour: '00', minutes: '15'});
        selectStopDate({hour: '02', minutes: '45'});
        expectDowntimeMessageToMatch('from 12:15am to 2:45am on Thursday 1 January.');
        expectScheduleMessageToMatch('from 12:15am on Wednesday 31 December');
      });

      it('includes both dates when they differ' , function() {
        selectStartDate();
        selectStopDate({day: '2', hour: '03'});
        expectDowntimeMessageToMatch('from 1am on Thursday 1 January to 3am on Friday 2 January.');
      });

      it('treats midnight on the next consecutive day as the same date' , function() {
        selectStartDate({hour: '22', day: '1'});
        selectStopDate({hour: '00', day: '2'});
        expectDowntimeMessageToMatch('from 10pm to midnight on Thursday 1 January.');
        expectScheduleMessageToMatch('from 10pm on Wednesday 31 December');
      });

      it('handles incorrect dates in the same way as rails', function() {
        selectStartDate({day: '29', month: '2'});
        selectStopDate({day: '5', month: '3'});
        expectDowntimeMessageToMatch('from 1am on Sunday 1 March to 1am on Thursday 5 March.');
        expectScheduleMessageToMatch('from 1am on Saturday 28 February');
        expectEnabledForm();
      });
    });
  });

  function expectDowntimeMessageToMatch(text) {
    expect(form.find('.js-downtime-message').val()).toMatch(text);
  }

  function expectDowntimeMessageToBe(text) {
    expect(form.find('.js-downtime-message').val()).toBe(text);
  }

  function expectScheduleMessageToMatch(text) {
    expect(form.find('.js-schedule-message').text()).toMatch(text);
  }

  function expectDisabledForm() {
    expect(form.find('.js-submit:disabled').length).toBe(1);
    expect(form.find('.js-downtime-message:disabled').length).toBe(1);
    expectScheduleMessageToMatch('Please select a valid date range');
  }

  function expectEnabledForm() {
    expect(form.find('.js-submit:disabled').length).toBe(0);
    expect(form.find('.js-downtime-message:disabled').length).toBe(0);
  }

  function selectStartDate(dateObj) {
    selectDate('.js-start-time', dateObj);
  }

  function selectStopDate(dateObj) {
    selectDate('.js-stop-time', dateObj);
  }

  function selectDate(selector, dateObj) {
    var selects = $(selector + ' select');

    dateObj = dateObj || {};

    selects.eq(0).val(dateObj.hour || '01');
    selects.eq(1).val(dateObj.minutes || '00');
    selects.eq(2).val(dateObj.day || '1');
    selects.eq(3).val(dateObj.month || '1');
    selects.eq(4).val(dateObj.year || '2015').trigger('change');
  }
});

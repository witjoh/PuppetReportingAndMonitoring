Getting it running
==================

Code is tested on a fc20, against a remote puppetdb 2.0.0 (puppet 3.6.1) installed on a centos 6.5

* due to the hash syntax, ruby version 1.9.3 or better is needed
* sudo `yum install gcc-c++`
* `sudo gem install execjs -v 2.0.2
  * dashing depends on this version, clashes with coffee-script, which will pull in 2.1.0)
  * if new versions are installed, use 'gem uninstall execjs' and remove a;; versions other than v2.0.2
* `sudo gem install dashing`
* `sudo gem install bundler`

Using the provided code
=======================

* unpack the code
* cd \<chapter\>/puppetdash
* `bundle install`
* if not running on the puppetdb
  * change all references `localhost` to puppetdb server host name
* `dashing start`
  * A demo dashboard should be available at `http://localhost:3030`

Changes done to the code
========================

* In `jobs/puppet.rb`
  * convert the local time (`Time.now`) to UTC using the `gmtime` method. Timestamps are recorded in UTS in puppetdb

    utc_time = Time.now.gmtime  
    time_past = (utc_time - 1800)  
    ftime_now = utc_time.strftime("%FT%T")  
    ftime_past = time_past.strftime("%FT%T")  

  * Added the puppetdb variable, and adjusted the URI's.
* in `dashboard/puppet.erb`
  * the widgets for the changed/pending/failed  adjusted for the meter widget (were still number widget)

    
    `<li data-row="1" data-col="1" data-sizex="1" data-sizey="1">  
      <div data-id="pupchanged" data-view="Meter" data-min="0" data-max="100" data-title="Changed" style="background-color:#96bf48"></div>  
    </li>  
    <li data-row="1" data-col="1" data-sizex="1" data-sizey="1">  
      <div data-id="puppending" data-view="Meter" data-min="0" data-max="100" data-title="Pending" ></div>  
    </li>  
    <li data-row="1" data-col="1" data-sizex="1" data-sizey="1">  
      <div data-id="pupfailed" data-view="Meter" data-min="0" data-max="100" data-title="Failed" class="status-danger"></div>  
    </li>`  
    
* Added in the README.md of the code, that the variable puppetdb='localhost' should be adjusted when using a remote puppetdb



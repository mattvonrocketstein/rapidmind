defmodule RaspTest do
	use ExUnit.Case
	test "RegexList test1" do
    	tstring="foo"
    	assert RegexList.all_matches(["foo"], tstring)==["foo"]
  	end	
  	test "RegexList test1" do
    	tstring="bleep bar bop foo"
    	assert RegexList.all_matches(["foo", "bar"], tstring)==["foo", "bar"]
  	end	
  	test "RegexList test1" do
    	tstring="bleep bop foo"
    	assert RegexList.all_matches(["foo", "bar"], tstring)==["foo"]
  	end
	test "RegexList test4" do
		tstring = "bleep boop"
    	assert RegexList.all_matches(["foo", "bar"], tstring)==[]
  	end
  	test "WebPage.process_page returns nil when there are no matches" do
		webpage=%WebPage{:rules=>["foo"], :body=>"bar"} 
		assert WebPage.process_page(webpage) == nil
  	end
  	test "WebPage.clean can be called repeatedly" do
		webpage=%WebPage{:rules=>["foo"], :body=>"bar"}
		webpage|>WebPage.clean|>WebPage.clean == webpage
  	end
  	test "WebPage.process_page returns WebPage when there are matches" do
		webpage=%WebPage{:rules=>["foo"], :body=>"foo bar baz"} 
		assert WebPage.process_page(webpage).__struct__ == WebPage
  	end
  	test "WebPage.process_page returns" do
		webpage=%WebPage{
			:url=>"https://www.reddit.com/r/devops/comments/3u21ew/ubuntuchefsolorails_deployment/",
 			:rules=>["foo"], :body=>"foo bar baz"
 		} 
		assert WebPage.process_page(webpage).__struct__ == WebPage
  	end
  end

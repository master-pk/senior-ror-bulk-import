# Intro
This is a very basic app that holds a collection of companies data including its employee and leaves policy information. In this task, you will be required to develop new features according to the following user story.

## User story
As a user/admin, I want to be able to do bulk import by uploading a CSV file containing information of users and its policy so that I can save time onboarding users.

User can upload employee data by going to a new page. This new page will have a form that has 2 form input. The first one should be a drop down of the company. The second one should be the file form input in which user/admin can select the file. There is a sample csv data in the source code that you can refer to `spec/fixtures/valid_sample.csv`.

### Note
* User needs to select the company they are importing for from the web page
* Any new policy from the csv will be automatically created upon the import, eg. if Sick Leave policy does not exist in the company but it presents in the csv, then we should create the policy for Sick Leave
* The policy columns may contain multiple policies and separated by pipe (|)
* The column *Report To* is meant for the reporting line of employee. An employee can only report to another employee. The one who does not have reporting line is the BOSS

### Validation :

* Company should exist
* Should follow model validation (User and Policy)
* Only process csv file
* Reject if no csv file uploaded


### Definition of done :

* If valid file upload user should see success messages.
* If the user tries to upload a non-CSV file, it should say  that file is invalid
* If some of the information provided within CSV file not valid (violating model validation)
* It should be able to handle hundreds of thousands of records.
* Users should be able to find if any invalid data was entered.
---

## Objective :

* Develop the feature based on the requirement/user story
* Follow best practices (coding style, security etc)
* Ensure code readability and design for scalable, robust application.
* Write test RSpec for unit and integration. Both for existing and new features.
* You may install gems that you need
* You may change the current implementation if needed or make assumptions you want.
* Readme

## My Implementation:

* Created a model FileUpload, which will track the FileUploads in the system. FileUpload is polymorphic to support files of different types for e.g Company
* Created a page to upload Company employees csv.
* When file is uploaded a message is shown to user and file is sent in background for processing. For background jobs, I used sidekiq.
* File processing is divided in two steps - Validation and Creation
* Since file can have millions of rows, distributed file processing is used. E.g if file has 2million rows, 20 jobs with 100K records each will process it concurrently.
* Batches are used for fetching and inserting data into MySQL.
* Redis is used for syncing among the jobs and handling the dependent job of linking mangers to employees.
* I have added comments in the code where required.
* For showing errors, I have added the error log along with status in FileUpload. When the processing is completed the status is updated accordingly. In case of error, a log file is also attached to show errors in the rows.
* Added Rspecs - **rspec --tag file_upload_test spec -fd** Existing specs are not fixed.
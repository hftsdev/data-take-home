# Millions Data Take Home

## Requirements

1. **We would like to know a few details about the data set in general:**
   - **What is the average transaction value?**
   - **What is the average transaction value / user?**
   - **How much are users spending per month?**
2. **Please provide a report showing the number of days a user spent per week.**
3. **Free range: What other insights do you gather from the data? If you could visualize something you find would be amazing**
4. **Please predict each user's next month spend**

---

## Submission Items

1. [Python Notebook](https://github.com/hftsdev/data-take-home/blob/main/take-home.ipynb) with work shown for questions 1, 2 and 4.
2. A [Superset](http://107.23.169.110:8088/superset/dashboard/millions) dashboard that contains some visualizations to the answers to questions 1 & 2 but mainly was fulfilling question 3's free range requirements.
3. Full outputs for Questions [1b](https://github.com/hftsdev/data-take-home/blob/main/Output%20Data/avg_tran_per_user.csv), [1c](https://github.com/hftsdev/data-take-home/blob/main/Output%20Data/monthly_spend_per_user.csv) & [2](https://github.com/hftsdev/data-take-home/blob/main/Output%20Data/days_users_spent_week.csv).
3. [SQL queries](https://github.com/hftsdev/data-take-home/blob/main/models.sql) used for modeling

---

## Notes

- A MySQL database was created for both modeling and visualization purposes and credentials will be provided via email.
- Superset was used as a constraint and isn't as feature complete as something such as Tableau, a server was spun up and access will be provided via email.
- All of the deliverables are very ad-hoc in nature and aren't how I would typically deliver, happy to talk through ways I would normally go about delivering.

---

## Assumptions

- I treated the question *How much are users spending per month?* as individual users and not overall.
- Some of the visualizations that were created in Superset were based on conversations that were had around what was important to the business.
- I kept the visualizations to only one dashboard but there are a number of ways I would have went further. Of of the ways would have been setting up daily/weekly/monthly dashboards or possibly even one that could be modified with filters. The other would be to expand on the customers with increased/decreased spend and building out something that focuses solely on that.

---

## Prediction

Predicting each user's next month spend was a little difficult given the data set. A couple of things that made it difficult were:

- Some of the users didn't have two months worth of spend so they were excluded from the prediction.
- Given the date range of the spending it was particulary difficult because of the seasonality of the spending. The numbers reflected in the prediction was skewed heavily because of holiday spending. If given a larger data set the seasonality could be built into the model.
- The prediction based on the next month was also difficult with only two data points, a weekly prediction could have been a little more accurate but not much at this stage.

A simple Linear Regression was used for the prediction but given the constraints the data set didn't necessarily fit a linear model. With more data points a Random Forest or Polynomial Regression might have been a better fit. With a little more data the model will inheritly get better and moving toward a daily or weekly spend prediction could incorporate holidays, days of the week, days of the year etc... to help aid a better overall model. The smaller prediction models could be used to build out the larger monthly and yearly models in the future.

Because it was a linear model I forced anything negative to zero on an individual user basis

---

## Superset

[Dashboard](http://107.23.169.110:8088/superset/dashboard/millions)

The username/password for exploring the live dashboard will be provided in the email for the submission.

An [image](https://github.com/hftsdev/data-take-home/blob/main/Dashboard.png) of the dashboard is also included in the repo.
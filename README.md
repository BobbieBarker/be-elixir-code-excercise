# Backend code exercise

Hi there!

If you're reading this, it means you're now at the coding exercise step of the engineering hiring process. We're really happy that you made it here and super appreciative of your time!

In this exercise you're asked to create a Phoenix application and implement some features on it.

> 💡 The Phoenix application is an API

If you have any questions, don't hesitate to reach out directly to [code_exercise@remote.com](mailto:code_exercise@remote.com).

## Expectations

- It should be production-ready code - the code will show us how you ship things to production and be a mirror of your craft.
  - Just to be extra clear: We don't actually expect you to deploy it somewhere or build a release. It's meant as a statement regarding the quality of the solution.
- Take whatever time you need - we won’t look at start/end dates, you have a life besides this and we respect that! Moreover, if there is something you had to leave incomplete or there is a better solution you would implement but couldn’t due to personal time constraints, please try to walk us through your thought process or any missing parts, using the “Implementation Details” section below.

## What will you build

A phoenix app with 2 endpoints to manage users.

We don’t expect you to implement authentication and authorization but your final solution should assume it will be deployed to production and the data will be consumed by a Single Page Application that runs on customer’s browsers.

To save you some setup time we prepared this repo with a phoenix app that you can use to develop your solution. Alternatively, you can also generate a new phoenix project.

## Requirements

- We should store users and salaries in PostgreSQL database.
- Each user has a name and can have multiple salaries.
- Each salary should have a currency.
- Every field defined above should be required.
- One user should at most have 1 salary active at a given time.
- All endpoints should return JSON.
- A readme file with instructions on how to run the app.

### Seeding the database

- `mix ecto.setup` should create database tables, and seed the database with 20k users, for each user it should create 2 salaries with random amounts/currencies.
- The status of each salary should also be random, allowing for users without any active salary and for users with just 1 active salary.
- Must use 4 or more different currencies. Eg: USD, EUR, JPY and GBP.
- Users’ name can be random or populated from the result of calling list_names/0 defined in the following library: [https://github.com/remotecom/be_challengex](https://github.com/remotecom/be_challengex)

### Tasks

1. 📄 Implement an endpoint to provide a list of users and their salaries
    - Each user should return their `name` and active `salary`.
    - Some users might have been offboarded (offboarding functionality should be considered out of the scope for this exercise) so it’s possible that all salaries that belong to a user are inactive. In those cases, the endpoint is supposed to return the salary that was active most recently.
    - This endpoint should support filtering by partial user name and order by user name.
    - Endpoint: `GET /users`

2. 📬 Implement an endpoint that sends an email to all users with active salaries
    - The action of sending the email must use Remote’s Challenge lib: [https://github.com/remotecom/be_challengex](https://github.com/remotecom/be_challengex)
    - ⚠️ This library doesn’t actually send any email so you don’t necessarily need internet access to work on your challenge.
    - Endpoint: `POST /invite-users`

### When you're done

- You can use the "Implementation Details" section to explain some decisions/shortcomings of your implementation.
- Open a Pull Request in this repo and send the link to [code_exercise@remote.com](mailto:code_exercise@remote.com).
- You can also send some feedback about this exercise. Was it too big/short? Boring? Let us know!

---

## How to run the existing application

You will need the following installed:

- Elixir >= 1.14
- Postgres >= 14.5

Check out the `.tool-versions` file for a concrete version combination we ran the application with. Using [asdf](https://github.com/asdf-vm/asdf) you could install their plugins and them via `asdf install`.

### To start your Phoenix server

- Run `mix setup` to install, setup dependencies and setup the database
- Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

---

## Implementation details

* Users.find_recent_and_active_salaries/1
  * query performance:
    * There is probably a more elegant and possibly more performative solution available with a postgres window function. Choosing a solution for a problem like this is a balancing act between the ideal and a good enough solution to go to market with. For some platforms the current implementation of find_recent_and_active_salaries/1 might be good enough for several years. It is difficult to know what the correct answer is with out a clear picture of the production environment. The best way to get an indication would be to manually execute the query in the production database before shipping the feature to prod. Additionally, it would be a good idea to take a look at the query plan the database is generating and fix any low hanging fruit. If this kind of preliminary investigative work showed that the union query was going to produce unacceptable performance results in production then it might be time to dig in and write a window function or explore other solutions.
  * pagination:
    * because the results are not sorted by name with the query, we would have to rewrite the current implementation if we wanted to support pagination on this end point. If we were paginating the results of the query another possible solution would be to first select the users we need and then to load the recent and active salary info onto our paginated user results.
* UserController.send_user_invitations/0 might not be suitable for a high volume call:
  * Just like it says in the docs a Task.Supervisor is a single process responsible for starting other processes. If it cannot clear out it's message queue quickly enough in some applications the Task.Supervisor could become a performance bottleneck. Elixir gives us an option for addressing this bottleneck through partitioning, but depending on the needs of the business, the platform, and how the nodes look when they are running under load, we might want to consider other solutions that could give us greater garuantees or allow us to execute our business logic on a node other than our webserver. Allowing webserver CPU to be spent on handling traffic instead of background jobs. Two possible options might be erlang rpc or a job queue such as oban.
* UserController.index/2 query param validation:
  * Production systems have actual query param validation that return a bad request error for invalid query params. I wanted to timebox my efforts on the assignment so I opted to not implement the abstractions necessary for validating requests. Generally speaking, in my opinion, the correct way to implement query param validation on a rest endpoint for a phoenix server would be to implement a validation plug that can be invoked inside a controler like so:

```elixir
defmodule FooWeb.FooController do
  plug Validator, IndexQueryParams when action === :index
end
```

  The IndexQueryParams module should implement the callbacks defined in the Validator module/behavior. As well as a changeset applying our validation logic. This behaviour should be used across all validation modules allowing for a predictable and common validation interface to be consumed by our Validator plug. The behaviour should require two callbacks. First, `config/0` which indicates what part of the incoming request is to be validated, i.e: query params, body, or path. Next it should have a `validate/1` function that can be invoked to validate the subject with the changeset defined in IndexQueryParams. If the subject is invalid the request can be halted and an error immediately returned to the caller.

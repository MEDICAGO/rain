import React, { Component } from "react";
import { Progress, Table } from "reactstrap";
import { parseDate } from "../utils/date";
import { fetchEvents } from "../utils/fetch";
import Error from "./Error";
import { SessionBar } from "./SessionBar";
import { niceTime, SessionStatusBadge } from "./utils";

interface Props {
  id: string;
}

interface State {
  error: string;
  session: any;
  submitCount: number;
  tasksCount: number;
  tasksRunning: number;
  tasksFinished: number;
  objsCount: number;
  objsFinished: number;
}

class Session extends Component<Props, State> {
  readonly state: State = {
    error: null,
    session: null,
    submitCount: 0,
    tasksCount: 0,
    tasksRunning: 0,
    tasksFinished: 0,
    objsCount: 0,
    objsFinished: 0
  };
  private readonly unsubscribe: () => void;

  constructor(props: Props) {
    super(props);
    this.unsubscribe = fetchEvents(
      { session: { value: +props.id, mode: "=" } },
      events => {
        let state = { ...this.state };
        for (const event of events) {
          const type = event.event.type;
          if (type === "TaskFinished") {
            state.tasksRunning -= 1;
            state.tasksFinished += 1;
          } else if (type === "TaskStarted") {
            state.tasksRunning += 1;
          } else if (type === "ClientSubmit") {
            state.submitCount = state.submitCount += 1;
            state.tasksCount += event.event.tasks.length;
            state.objsCount += event.event.dataobjs.length;
          } else if (type === "SessionNew") {
            const session = {
              client: event.event.client,
              created: event.time,
              finished: null as any,
              status: "Open",
              message: "",
              spec: event.event.spec
            };
            state = { ...state, session };
          } else if (type === "SessionClosed") {
            let status = "Closed";
            if (event.event.reason === "Error") {
              status = "Error";
            }
            if (event.event.reason === "ServerLost") {
              status = "Server lost";
            }
            state.session.finished = event.time;
            state.session.status = status;
            state.session.message = event.event.message;
            state.tasksRunning = 0;
            this.unsubscribe();
          }
        }
        this.setState(state);
      },
      error => {
        this.setState(() => ({ error }));
      }
    );
  }

  componentWillUnmount() {
    this.unsubscribe();
  }

  render() {
    const state = this.state;
    const session = state.session;
    const taskProgress = 100 * (state.tasksFinished / state.tasksCount);
    const end =
      session && session.finished
        ? parseDate(session.finished).getTime()
        : new Date().getTime();
    const duration =
      session && (end - parseDate(session.created).getTime()) / 1000;

    return (
      <div>
        <Error error={this.state.error} />
        {session && (
          <div>
            <h1>
              Session '{state.session.spec.name}' ({this.props.id})
            </h1>

            <SessionBar id={this.props.id} />

            <Table bordered>
              {/*<thead>
              <tr><th>Key</th><th>Value</th><th>Client</th><th>Created</th><th>Finished</th></tr>
              </thead>*/}
              <tbody>
                <tr>
                  <td>Status</td>
                  <td>
                    <SessionStatusBadge status={session.status} />
                    <p className="text-left text-monospace">
                      {session.message}
                    </p>
                  </td>
                </tr>
                <tr>
                  <td>Submits</td>
                  <td>{state.submitCount}</td>
                </tr>
                <tr>
                  <td>Tasks</td>
                  <td>
                    <div className="text-center">
                      {state.tasksFinished}/{state.tasksCount} (
                      {taskProgress.toFixed(1)}
                      %)
                    </div>
                    <Progress multi>
                      <Progress
                        bar
                        value={state.tasksFinished}
                        max={state.tasksCount}
                      />
                      <Progress
                        bar
                        animated
                        color="warning"
                        value={state.tasksRunning}
                        max={state.tasksCount}
                      />
                    </Progress>
                    {state.tasksRunning > 0 && (
                      <div> {state.tasksRunning} running</div>
                    )}
                  </td>
                </tr>
                <tr>
                  <td>Data Objects</td>
                  <td>{state.objsCount}</td>
                </tr>
                <tr>
                  <td>Client</td>
                  <td>{session.client}</td>
                </tr>
                <tr>
                  <td>Duration</td>
                  <td>{niceTime(duration)}</td>
                </tr>
              </tbody>
            </Table>
          </div>
        )}
      </div>
    );
  }
}

export default Session;

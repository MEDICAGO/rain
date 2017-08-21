@0xb3195a92eff52478;

using import "common.capnp".TaskId;
using import "common.capnp".WorkerId;
using import "common.capnp".DataObjectId;
using import "common.capnp".Additional;
using import "common.capnp".SessionId;
using import "common.capnp".TaskState;
using import "common.capnp".DataObjectState;
using import "datastore.capnp".DataStore;

struct ServerInfo {
  nWorkers @0 :Int32;
  # Number of active workers
}

interface ClientService {
    getServerInfo @0 () -> ServerInfo;
    # Get information about server

    newSession @1 () -> (sessionId: SessionId);
    # Ask for a new session

    removeSession @2 (sessionId :SessionId) -> ();
    # Remove session from worker, all running tasks are stopped,
    # all existing data objects are removed

    submit @3 (tasks :List(Task), objects :List(DataObject)) -> ();
    # Submit new tasks and data objects into server
    # allTaskId / allDataObjectsId is NOT allowed

    remove @4 (objectIds :List(DataObjectId)) -> ();
    # Removed "keep" flag from data objects
    # It is an error if called for non-keep object 
    # allTaskId / allDataObjectsId is allowed

    wait @5 (taskIds :List(TaskId), objectIds: List(DataObjectId)) -> ();
    # Wait until all given data objects are not produced
    # and all given task finished.
    # allTaskId / allDataObjectsId is allowed

    waitSome @6 (taskIds: List(TaskId),
                 objectIds: List(DataObjectId)) -> (
                             finishedTasks: List(TaskId),
                             finishedObjects: List(DataObjectId));
    # Wait until at least one data object or task is not finished.
    # It may return more objects/tasks at once.
    # finished_tasks and finished_objects are both returned empty
    # only if taskIds and objectsIds are empty.
    # allTaskId / allDataObjectsId is allowed

    getState @7 (taskIds: List(TaskId),
               objectIds: List(DataObjectId)) -> Update;
    # Get current state of tasks and objects
    # allTaskId / allDataObjectsId is allowed

    getDataStore @8 () -> (store :DataStore);
    # Returns the data handle of the server. It does not make sense to take more
    # than one instance of this.

    terminateServer @9 () -> ();
    # Quit server; the connection to the server will be closed after this call
}

struct Update {
    tasks @0 :List(TaskUpdate);
    objects @1 :List(DataObjectUpdate);

    struct TaskUpdate {
        id @0 :TaskId;
        state @1 :TaskState;
    }

    struct DataObjectUpdate {
        id @0 :DataObjectId;
        state @1 :DataObjectState;
        size @2 :UInt64;
        # Only valid when the state is `finished` and `removed`, otherwise should be 0.
    }
}

struct Task {
    id @0 :TaskId;
    inputs @1 :List(LabelledDataObject);
    outputs @2 :List(LabelledDataObject);
    taskType @3 :Text;
    taskConfig @4 :Data;
    additional @5 :Additional;

    nCpus @6 :Int32;
    # Number of request CPUs; will be replaced by more sophisticated
    # resource requests

    # Labels for Sid-referenced inputs
    struct LabelledDataObject {
        id @0 :DataObjectId;
        label @1 :Text;
    }
}


struct DataObject {
    id @0 :DataObjectId;
    keep @1 :Bool;
    data @2 :Data;
    additional @3: Additional;
}
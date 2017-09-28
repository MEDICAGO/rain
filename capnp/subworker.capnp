@0xf25243ae04134c6a;

using import "common.capnp".DataObjectId;
using import "common.capnp".TaskId;
using import "common.capnp".DataObjectType;

interface SubworkerControl {
    # This object serves also as bootstrap

    runTask @0 (task :Task) -> (data: List(LocalData));
    # Run the task, returns when task is finished

    removeObjects @1 (objectIds :List(DataObjectId)) -> ();
    # Remove object from Subworker
    # If object is "file" than the file is NOT removed, it is
    # a responsibility of the worker
}

interface SubworkerUpstream {

    register @0 (version :Int32,
                 subworkerId: Int32,
                 subworkerType: Text,
                 control :SubworkerControl) -> ();
    # Subworker ID is annoucted through environment variable RAIN_SUBWORKER_ID
    # We cannot assign subworker_id through RPC since ID has to be
    # allocated before process start, because we need to create files for redirection of stdout/stderr
    # and they already contains subworker_id in the name
}

struct Task {
    id @0 :TaskId;

    inputs @1 :List(InDataObject);
    outputs @2 :List(OutDataObject);

    taskConfig @3 :Data;

    struct InDataObject {
        id @0 :DataObjectId;
        data @1 :LocalData;
        label @2 :Text;
    }

    struct OutDataObject {
        id @0 :DataObjectId;
        type @1 :DataObjectType;
        label @2 :Text;
    }
}

struct LocalData {

    type @0 :DataObjectType;

    storage :union {
        cache @1 :Void;
        # Data is cached in subworker

        memory @2 :Data;
        # Actual content of the data object

        path @3 :Text;
        # The object is in file, the argument is the size in bytes

        stream @4 :Void;
        # TODO
    }
}
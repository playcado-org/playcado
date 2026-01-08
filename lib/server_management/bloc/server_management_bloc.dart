import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
part 'server_management_event.dart';
part 'server_management_state.dart';

class ServerManagementBloc
    extends Bloc<ServerManagementEvent, ServerManagementState> {
  ServerManagementBloc() : super(const ServerManagementState());
}

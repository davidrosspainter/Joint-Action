function ButtonState = ButtonStateParser_dp(GamepadButtonFlags)

GamepadButtonFlags = double(GamepadButtonFlags);

fields = {
    'LeftStick'
    'RightStick'};
masks = [
	64
    128
];

for i = 1:numel(fields)
    ButtonState.(fields{i}) = logical(bitand(GamepadButtonFlags,masks(i),'int32'));
end


